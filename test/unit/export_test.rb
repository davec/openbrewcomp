# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'
require 'tempfile'

class ExportTest < Test::Unit::TestCase

  def setup
    @bad_format = 'no_such_format'
  end

  tables = [ :award, :carbonation, :category, :club, :country, :entrant, :entry, :region, :right, :role, :strength, :style, :sweetness, :user ]

  [ :symbol, :string, :class ].each do |type|
    tables.each do |table|
      model = case type
              when :string then table.to_s
              when :class  then table.to_s.classify.constantize
              else              table
              end
      table_name = model.to_s.classify.constantize.table_name

      [ :csv, :yml ].each do |format|
        define_method "test_export_#{format}_for_#{table_name}_with_#{type.to_s.pluralize}" do
          export = Export.new([model], :format => format)
          assert_not_nil export

          assert_equal 'exported_data.zip', export.name
          assert_equal 'application/zip', export.type
          assert_match /\.zip$/, export.file
          assert export.data.length > 0

          # Test the zip file contents
          zip_contents = ZipFile::list(export.file, true)
          assert_equal 1, zip_contents.length
          assert_equal "#{table_name}.#{format}", zip_contents[0][:name]
          assert_equal :file, zip_contents[0][:type]
          assert zip_contents[0][:size] > 0
        end
      end

      define_method "test_invalid_export_format_for_#{table_name}_with_#{type.to_s.pluralize}" do
        assert_raise(ArgumentError, "Invalid format: #{@bad_format}") {
          export = Export.new([model], :format => @bad_format)
        }
      end
    end

    models = case type
             when :string then tables.collect{|t| t.to_s}
             when :class  then tables.collect{|t| t.to_s.classify.constantize}
             else              tables
             end

    [ :csv, :yml ].each do |format|
      define_method "test_export_#{format}_for_models_with_#{type.to_s.pluralize}" do
        export = Export.new(models, :format => format)
        assert_not_nil export
        assert_equal 'exported_data.zip', export.name
        assert_equal 'application/zip', export.type
        assert_match /\.zip$/, export.file
        assert export.data.length > 0

        # Test the zip file contents
        zip_contents = ZipFile::list(export.file)
        assert_equal models.length, zip_contents.length
        models.each do |model|
          table_name = model.to_s.classify.constantize.table_name
          assert_not_nil zip_contents.detect{|name| name == "#{table_name}.#{format}"}
        end
      end
    end

    define_method "test_invalid_export_format_for_models_with_#{type.to_s.pluralize}" do
      assert_raise(ArgumentError, "Invalid format: #{@bad_format}") {
        export = Export.new(models, :format => @bad_format)
      }
    end
  end

  def test_export_star_for_csv
    assert_raise(ArgumentError, "tables = * is invvalid for CSV exports") {
      export = Export.new('*', :format => :csv)
    }
  end

  def test_export_star_for_yaml
    format = 'yml'
    export = Export.new('*', :format => format)
    assert_not_nil export
    assert_equal 'exported_data.zip', export.name
    assert_equal 'application/zip', export.type
    assert_match /\.zip$/, export.file
    assert export.data.length > 0

    # Test the zip file contents
    zip_contents = ZipFile::list(export.file)
    exported_tables = Export.all_tables
    assert_equal exported_tables.length, zip_contents.length
    exported_tables.each do |table_name|
      assert_not_nil zip_contents.detect{|name| name == "#{table_name}.#{format}"}
    end
  end

end
