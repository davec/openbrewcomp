# -*- coding: utf-8 -*-

require 'zip/zip'
require 'iconv'

class Export

  attr_reader :name, :type

  def initialize(tables, options = {})
    @tables = tables
    @name = 'exported_data.zip'.freeze
    @type = 'application/zip'.freeze
    create(options)
  end

  def data
    IO.read(@zipfile)
  end

  def file
    @zipfile
  end

  def self.all_tables
    tables_to_skip = [ 'sessions' ]
    ActiveRecord::Base.connection.tables - tables_to_skip
  end

  def create(options)
    format = options[:format].to_s || 'yml'
    output_charset = options[:convert]

    # Check validity
    raise ArgumentError, "tables = * is invalid for #{format.upcase} exports" if @tables.to_s == '*' && format !~ /^ya?ml$/

    # Create a zip file, iterating until we get a name that's not already in use
    try_count = 0
    try_limit = 10
    begin
      try_count += 1
      @zipfile = "#{RAILS_ROOT}/tmp/#{Time.now.to_i.to_s(16)}#{rand(0x7fffffff).to_s(16)}.zip"
      Zip::ZipFile.open(@zipfile, Zip::ZipFile::CREATE) { |zipfile|
        # Delete the zip file when this object is destroyed by the garbage
        # collector. (This avoids the necessity of requiring the caller to
        # call the delete method.)
        ObjectSpace.define_finalizer(self, self._delete(@zipfile))

        if @tables.to_s == '*'
          sql = 'SELECT * FROM %s'
          Export.all_tables.each do |table|
            i = '0'
            zipfile.get_output_stream("#{table}.#{format}") { |f|
              begin
                data = table.classify.constantize.find(:all).inject({}) { |hash, record|
                  hash["#{table}_#{i.succ!}"] = record.attributes
                  hash
                }
              rescue NameError
                # The table does not map to a model so use raw SQL to get the data
                data = ActiveRecord::Base.connection.select_all(sql % table).inject({}) { |hash, record|
                  hash["#{table}_#{i.succ!}"] = record
                  hash
                }
              end
              f.puts data.to_yaml
            }
          end
        else
          @tables.each do |table|
            model = table.to_s.classify.constantize
            zipfile.get_output_stream("#{model.table_name}.#{format}") { |f|
              data = model.send(:export, format)
              output = charset_convert(data, output_charset)
              f.puts output
            } if model.respond_to?(:export)
          end
        end
      }
    rescue ArgumentError
      raise
    rescue NameError
      raise
    rescue Exception => e
      if try_count < try_limit
        retry
      else
        # Even after `try_limit' times we can't get a file?  Run away!
        raise 'Cannot create ZIP file'
      end
    end
  end

  def _delete(path)
    pid = $$
    lambda {
      if pid == $$
        File.unlink(path) if File.exist?(path)
      end
    }
  end

  private

    def charset_convert(data, charset)
      return charset.nil? ? data : Iconv.iconv(charset, "UTF-8", data)
    end

end
