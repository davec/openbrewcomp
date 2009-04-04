# -*- coding: utf-8 -*-

require 'set'
require 'tsort'

class PurgeOldData < ActiveRecord::Base

  attr_reader :errors

  @@tables_to_clear = [ 'flights', 'judging_sessions', 'entries', 'scores',
                        'category_preferences', 'time_availabilities' ].freeze
  cattr_reader :tables_to_clear

  def initialize(tables = @@tables_to_clear)
    @errors = Array.new
    @tables = tables.is_a?(Array) ? tables.collect(&:to_s) : [ tables.to_s ]
  end

  # Validate the specified tables
  def valid?
    @errors.clear
    tables_to_skip = [ 'sessions', 'schema_info' ]
    base_tables = (ActiveRecord::Base.connection.tables - tables_to_skip).to_set
    tables_to_purge = @tables.to_set
    unknown_tables = ((base_tables^tables_to_purge)|base_tables)-base_tables
    @errors << "Unknown or invalid #{pluralize(unknown_tables.length, 'table')}: #{unknown_tables.to_a.to_sentence}" unless unknown_tables.empty?

    return @errors.empty?
  end

  def zap
    # To speed things up, we call delete_all instead of destroy_all.  However,
    # this means that we must include any dependent tables in the deletion
    # (but not in the PK sequence reset).
    all_tables = get_dependent_tables(@tables)

    connection = ActiveRecord::Base.connection
    connection.transaction do
      all_tables.each{|table_name| table_name.classify.constantize.delete_all}
      if connection.respond_to?(:reset_pk_sequence!)
        @tables.each{|table_name| connection.reset_pk_sequence!(table_name)}
      end
      # Clear the organizer flag and staff_points from the judges table
      Judge.update_all(['organizer = ?, staff_points = ?', false, nil])
    end
  end

  private

    def pluralize(count, word)
      word + (count == 1 ? '' : 's')
    end

    # Get a list of all dependent tables, defined as tables that are listed in
    # a has_many relationship that are also marked as :dependent => :destroy as
    # well as any that are implied in a habtm relationship.  A topographically
    # sorted list of the original and dependent tables is returned.
    def get_dependent_tables(tables)
      models = Models.new
      tables.each do |table_name|
        begin
          requires = table_name.classify.constantize.reflections.select{|key,value|
            (value.macro == :has_many &&
             value.options[:dependent] == :destroy) ||
            (value.macro == :has_and_belongs_to_many)
          }.inject([]){|arr,(key,value)|
            if value.options.include?(:join_table)
              arr << value.options[:join_table].tableize
            else
              arr << (value.options[:class_name].tableize rescue value.name.to_s.tableize)
            end
          }
        rescue
          raise ArgumentError, "Model for table #{table_name} does not exist"
        end
        models.add_dependency(table_name, *requires)
      end
      models.tsort
    end

    class Models
      include TSort

      def initialize
        @dependencies = {}
      end

      def add_dependency(model, *requires)
        @dependencies[model] = requires
      end

      def tsort_each_node(&block)
        @dependencies.each_key(&block)
      end

      def tsort_each_child(node, &block)
        deps = @dependencies[node]
        deps.each(&block) if deps
      end

    end

end
