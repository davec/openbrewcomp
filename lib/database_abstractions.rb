# -*- coding: utf-8 -*-

# Provide abstractions of various functions that are not supported in all
# databases (e.g., functions that are in PostgreSQL and MySQL but not in
# SQLite).

module DatabaseAbstractions

  protected

    def sql_extract_year_from(column)
      # NOTE: We're not bothering with a more general solution because our
      # code is only concerned with extracting the year from dates.

      # SQLite does not have the extract() function
      if defined?(ActiveRecord::ConnectionAdapters::SQLite3Adapter) &&
         ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::SQLite3Adapter)
        "strftime('%Y',#{column})"
      else # PostgreSQL && MySQL
        "extract(year FROM #{column})"
      end
    end

    def sql_lpad(value, length, char = ' ')
      # SQLite lacks lpad()
      if defined?(ActiveRecord::ConnectionAdapters::SQLite3Adapter) &&
         ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::SQLite3Adapter)
        "substr(value || '#{char * length}', 1, length)"
      else # PostgreSQL && MySQL
        "lpad(#{value}, #{length}, '#{char}')"
      end
    end

    def sql_rpad(value, length, char = ' ')
      # SQLite lacks rpad()
      if defined?(ActiveRecord::ConnectionAdapters::SQLite3Adapter) &&
         ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::SQLite3Adapter)
        "substr('#{char * length}' || value, -1, length)"
      else # PostgreSQL && MySQL
        "rpad(#{value}, #{length}, '#{char}')"
      end
    end

end
