# -*- coding: utf-8 -*-

require 'set'
require 'tsort'

class PurgeOldData < ActiveRecord::Base

  attr_reader :errors

  @@tables_to_clear = [ 'flights', 'judging_sessions', 'entries', 'scores',
                        'category_preferences', 'time_availabilities' ].freeze
  @@optional_tables_to_clear = [ 'users', 'entrants', 'judges', 'clubs' ].freeze
  cattr_reader :tables_to_clear, :optional_tables_to_clear

  def initialize(additional_tables = nil)
    tables = (@@tables_to_clear + [ additional_tables ]).flatten.compact
    @errors = Array.new
    @tables = tables.collect(&:to_s)
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
      if all_tables.include?('users')
        # To avoid foreign key constraint errors if any of these tables are
        # not included in the purge.
        Judge.update_all("user_id = #{User.admin_id}")
        Entry.update_all("user_id = #{User.admin_id}")
        Entrant.update_all("user_id = #{User.admin_id}")
      end
      if all_tables.include?('clubs')
        # To avoid foreign key constraint errors if any of these tables are
        # not included in the purge.
        Judge.update_all("club_id = #{Club.independent.id}")
        Entrant.update_all("club_id = #{Club.independent.id}")
      end

      all_tables.each do |table_name|
        case table_name
        when 'users'
          # Only delete non-admin users
          table_name.classify.constantize.delete_all(['id NOT IN (?)', User.admins.collect(&:id)])
        when 'roles_users'
          # Do not delete roles belonging to admin users
          table_name.classify.constantize.delete_all(['user_id NOT IN (?)', User.admins.collect(&:id)])
        when 'clubs'
          # Do not delete Independent and Other
          table_name.classify.constantize.delete_all(['id NOT IN (?)', [ Club.other.id, Club.independent.id ] ])
        else
          table_name.classify.constantize.delete_all
        end
      end
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
            (value.macro == :has_many && value.options[:dependent] == :destroy) ||
            value.macro == :has_and_belongs_to_many
          }.inject([]){|arr,(key,value)|
            arr << (value.options[:join_table] || value.options[:class_name] || value.name).to_s.tableize
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
