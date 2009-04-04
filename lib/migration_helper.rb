# -*- coding: utf-8 -*-

module MigrationHelper

  # Non-rails-standard helper to facilitate
  # managing foreign key constraints.

  module ForeignKeys

    def add_foreign_key(from_table, from_column, to_table)
      sql_statement = %W{
        ALTER TABLE #{from_table}
        ADD CONSTRAINT #{self.to_fk_constraint_name(from_table, from_column)}
        FOREIGN KEY (#{from_column})
        REFERENCES #{to_table}(id)
      }
      sql_statement = sql_statement.join(' ')
      execute sql_statement
    end

    def drop_foreign_key(from_table, from_column)
      type = ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql' ? 'CONSTRAINT' : 'FOREIGN KEY'
      sql_statement = %W{
        ALTER TABLE #{from_table}
        DROP #{type} #{self.to_fk_constraint_name(from_table, from_column)}
      }
      sql_statement = sql_statement.join(' ')
      execute sql_statement
    end

    def to_fk_constraint_name(from_table, from_column)
      return "fk_#{from_table}_#{from_column}"
    end

  end

end
