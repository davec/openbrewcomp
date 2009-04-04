# -*- coding: utf-8 -*-

require 'zip/zip'
require 'tsort'
require 'active_record/fixtures'

class Import

  class ValidationError < StandardError; end

  attr_reader :errors

  def initialize(archive)
    @errors = Array.new
    @schema_info_table_name = ActiveRecord::Migrator.schema_info_table_name
    self.file_data = archive['file_data']
  end

  def file_data=(file_data)
    @file_data = file_data
  end

  # Validate the uploaded file data
  def valid?
    @errors.clear

    unless @file_data.blank?
      # Check for a valid ZIP file. The Content-Type is usually correct, but if
      # it's set by the client's browser based on the file extension and a file
      # with a .zip extension that is not actually a zip file is uploaded, we've
      # been lied to.
      begin
        status = @file_data.content_type.chomp =~ /^application\/zip$/ &&
                 @file_data.read(4) == "PK\003\004"
        @file_data.rewind
        @errors << "#{@file_data.original_filename} is not a ZIP archive" unless status
      rescue Exception => e
        @errors << "The file is not a valid ZIP archive"
      end
    else
      @errors << "You must select a file to upload"
    end

    return @errors.empty?
  end

  # Unarchive and validate the file, determine the load order, merge the
  # existing admin account with the new data, and load the files into the
  # database.
  def save
    return false unless @file_data && self.valid?

    begin
      create_extract_directory
      unarchive
      validate_archive_contents
      determine_load_order
      merge_admin_account
      load_data
    rescue Exception => e
      @errors << e.to_s
    else
      @file_data = nil
      @errors.clear
    ensure
      cleanup
    end

    return @errors.empty?
  end

  private

    # Create a unique, temporary, directory in which to extract the archive.
    def create_extract_directory
      # Create a directory to extract the files into
      try_count = 0
      try_limit = 10
      begin
        try_count += 1
        @zipdir = File.join(RAILS_ROOT, 'tmp', "#{Time.now.to_i.to_s(16)}#{rand(0x7fffffff).to_s(16)}.d")
        Dir.mkdir(@zipdir, 0700)
      rescue Exception => e
        if try_count < try_limit
          retry
        else
          # Even after `try_limit' times we can't create a unique directory?  Run away!
          raise 'Cannot create archive directory'
        end
      end
    end

    # Extract the archive in @zipdir
    def unarchive
      FileUtils.cd(@zipdir) { |dir|
        archive = 'data.zip'
        File.open(archive, 'wb') { |f| f.write(@file_data.read) }

        @files = Array.new
        Zip::ZipFile.open(archive) { |zipfile|
          zipfile.each { |e|
            filepath = e.name
            FileUtils.mkdir_p(File.dirname(filepath))
            zipfile.extract(e, filepath)
            @files << filepath
          }
        }

        # Save the file extension that was used to create the dump files.
        # WARNING: This assumes that all files have the same extension,
        # which is how the Export model generates them.
        @extname = File.extname(@files[0])

        # Get the table names from the file list
        @tables = @files.collect{|f| File.basename(f, @extname)}
      }
    end

    # Perform various checks to validate the integrity of the archive.
    # Additional tests may be made in subsequent actions.
    def validate_archive_contents
      begin
        # Check for schema_info.yml
        schema_info_file = File.join(@zipdir, @schema_info_table_name + @extname)
        raise ValidationError, "The imported data is missing the #{@schema_info_table_name} table" unless File.exist?(schema_info_file)

        # Verify that schema_info can be loaded
        schema_info = YAML.load_file(schema_info_file)
        raise ValidationError, "Invalid schema info data" unless schema_info.size == 1

        # Verify that the imported table names are the same as the exportable table names
        current_tables = Export.all_tables.sort
        imported_tables = @tables.sort
        raise ValidationError, "The imported data tables do not match the current data tables." unless current_tables == imported_tables

        # Verify that the imported schema version matches the current schema version
        current_schema_version = ActiveRecord::Migrator.current_version
        imported_schema_version = schema_info.values[0]['version'].to_i
        raise ValidationError, "The schema version of the imported data (#{imported_schema_version}) does not match the current schema version (#{current_schema_version})." unless imported_schema_version == current_schema_version
      rescue ValidationError => e
        raise e.to_s
      rescue Exception => e
        # Some other error
        raise "The imported data contains an invalid #{@schema_info_table_name} table: #{e.to_s}"
      end
    end

    # Determine the order in which to load the tables.  Any dependent tables
    # must be loaded before the tables that depend on them.
    def determine_load_order
      classes = @files.collect{|f| File.basename(f, File.extname(f))}
      models = Models.new
      @tables.each { |table_name|
        begin
          requires = table_name.classify.constantize.reflections.select { |key, value|
            value.macro == :belongs_to
          }.inject([]) { |arr, (key, value)|
            # Check first for a specific class name in the value's
            # options attribute (as generated by a
            #   belongs_to :parent, :class_name => 'Other'
            # in the controller) before defaulting to the value's
            # name attribute.
            arr << (value.options[:class_name].tableize rescue value.name.to_s.tableize)
          }
        rescue NameError => e
          # table_name does not map to an existing model. This should only happen
          # with schema_info and join tables.
          case table_name
          when @schema_info_table_name
            requires = []
          else
            # The "class" is most likely a join table, which is dependent on
            # both models, e.g., 'rights_roles' depends on 'rights' and 'roles'.
            # WARNING: This only works for single-word models, i.e., only one
            # underscore in the name, but we don't (currently) have any join
            # tables that include a multi-word model.
            dependent_tables = table_name.split('_')
            case dependent_tables.length
            when 2
              begin
                dependent_tables.collect{|t| t.classify.constantize}
              rescue
                # If the dependent table names are both plural, they most likely
                # are part of a join table; otherwise, they're separate parts of
                # a single table that belongs to a multi-word model.
                if dependent_tables.select{|t| is_plural(t)}.length == 2
                  raise ArgumentError, "Dependent tables missing for join table #{table_name}"
                else
                  requires = []
                end
              else
                requires = dependent_tables
              end
            when 1
              # Should never get here
              raise ArgumentError, "Model for table #{table_name} does not exist"
            else
              raise ArgumentError, "Unsupported join table name: #{table_name}"
            end
          end
        end
        models.add_dependency(table_name, *requires)
      }
      @load_order = models.tsort
    end

    # Cheap hack to determine if a string is plural.
    def is_plural(string)
      string.singularize.pluralize == string
    end

    # Replace the imported admin account with the current admin account.
    # This keeps the local admin from being locked out or having to manualy
    # reset the password.
    def merge_admin_account
      current_admin = User.find(User.admin_id)

      users_file = File.join(@zipdir, 'users' + @extname)
      users = YAML.load_file(users_file)
      raise "Imported users table is empty" unless users.size > 0

      imported_admin = users.find{|key, value| value['login'] == current_admin.login}
      raise "Imported users table has no #{current_admin.login} account" if imported_admin.nil?

      # Verify the keys of the imported users table match the current users table
      raise "Imported users table is incompatible with the current users table" unless users[imported_admin[0]].keys.sort == current_admin.attributes.keys.sort

      # Replace the imported admin account with the current admin account
      users[imported_admin[0]] = current_admin.attributes

      # Write the updated users data
      File.open(users_file, 'w') do |f|
        YAML.dump(users, f)
      end
    end

    # Load the data from @zipdir
    def load_data
      ActionController::Base.benchmark("Loading data: #{@load_order.join(', ')}", Logger::DEBUG, false) do
        Fixtures.create_fixtures(@zipdir, @load_order)
      end
    end

    # Delete @zipdir (recursively)
    def cleanup
      if @zipdir
        FileUtils.rm_r @zipdir, :force => true, :secure => true
      end
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
