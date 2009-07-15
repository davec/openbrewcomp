# -*- coding: utf-8 -*-

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'stringio'

class ActiveSupport::TestCase
  include AuthenticatedTestHelper

  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # `assert_select_feed' was plucked from the assert_select_patch.diff
  # attached to Rails Trac ticket 5936 since is was removed in the
  # integration but is a useful addition for testing the RSS feed
  # controller.
  def assert_select_feed(type, version = nil, &block)
    root = HTML::Document.new(@response.body, true, true).root
    case [type.to_sym, version && version.to_s]
      when [:rss, "2.0"], [:rss, "0.92"], [:rss, nil]
        version = "2.0" unless version
        selector = HTML::Selector.new("rss:root[version=?]", version)
      when [:atom, "0.3"]
        selector = HTML::Selector.new("feed:root[version=0.3]")
      when [:atom, "1.0"], [:atom, nil]
        selector = HTML::Selector.new("feed:root[xmlns='http://www.w3.org/2005/Aton']")
      else
        raise ArgumentError, "Unsupported feed type #{type} #{version}"
    end
    assert_select root, selector, &block
  end

  # Assert that an ActiveScaffold table for an index page exists and
  # contains the specified number of rows.
  def assert_select_active_scaffold_index_table(count)
    assert_select "div##{@controller.active_scaffold_id}" do
      assert_select 'div.active-scaffold-header', :count => 1
      assert_select "div##{@controller.active_scaffold_content_id} > table > tbody.records > tr.record", :count => count
    end
  end

  # Assert that the response contains PDF content
  def assert_pdf_response
    assert @response.headers['Content-Length'].to_i > 0
    assert_equal 'application/pdf', @response.headers['Content-Type']
    assert_kind_of Proc, @response.body
    output = StringIO.new
    assert_nothing_raised { @response.body.call(@response, output) }
    assert_equal output.size, @response.headers['Content-Length'].to_i
    output.rewind
    assert_match /%PDF-1.\d/, output.read(8)
  end

  # Assert that the response contains ZIP content
  def assert_zip_response
    assert @response.headers['Content-Length'].to_i > 0
    assert_equal 'application/zip', @response.headers['Content-Type']
    assert_equal "PK\003\004", @response.body[0,4]
  end

  # Assert that an array contains a specific element
  def assert_included(expected_element, actual_array, message = nil)
    full_message = build_message(message, <<EOT, expected_element, actual_array)
<?> expected but was
<?>.
EOT
    assert_block(full_message) { actual_array.include?(expected_element) }
  end

  # Get an uploadable file (from Rails Cookbook, recipe 7.21)
  def uploadable_file(relative_path, content_type = "application/octet-stream", filename = nil)
    file_object = File.open("#{RAILS_ROOT}/#{relative_path}", 'r')

    (class << file_object; self; end;).class_eval do
      attr_accessor :original_filename, :content_type
    end

    file_object.original_filename ||= File.basename("#{RAILS_ROOT}/#{relative_path}")
    file_object.content_type = content_type

    file_object
  end

end
