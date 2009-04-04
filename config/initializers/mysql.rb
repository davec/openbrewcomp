if ActiveRecord::ConnectionAdapters.const_defined?(:MysqlAdapter)

  # Configure sane and consistent settings for MySQL.
  class ActiveRecord::ConnectionAdapters::MysqlAdapter
    def connect_with_strict
      connect_without_strict

      # NOTE: According the the MySQL documentation, the ANSI mode is equivalent
      # to REAL_AS_FLOAT, PIPES_AS_CONCAT, ANSI_QUOTES, IGNORE_SPACE, but this is
      # not quite correct. By specifying ANSI, those 4 options are indeed applied,
      # but so is NO_TABLE_OPTIONS which prevents mysqldump from including table
      # options that are required to be able to properly replicate the development
      # database in the test environment.
      #
      # We also throw in the STRICT_TRANS_TABLES option to prevent invalid data
      # from being inserted and the ONLY_FULL_GROUP_BY option to be compatible
      # with PostgreSQL (even though the POSTGRESQL meta option does not include
      # ONLY_FULL_GROUP_BY, it is required to avoid developing code with MySQL
      # that won't work with PostgreSQL because of the different behavior with
      # the GROUP BY and HAVING clauses).

      execute("SET sql_mode = 'real_as_float,pipes_as_concat,ansi_quotes,ignore_space,strict_trans_tables,only_full_group_by'")
    end
    alias_method_chain :connect, :strict
  end

end
