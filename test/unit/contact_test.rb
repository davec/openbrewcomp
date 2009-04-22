# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class ContactTest < ActiveSupport::TestCase

  def test_should_create_new_contact
    assert_difference 'Contact.count' do
      contact = create_contact
      assert !contact.new_record?, "#{contact.errors.full_messages.to_sentence}"
    end
  end

  def test_should_not_add_duplicate_contact
    assert_no_difference 'Contact.count' do
      # The 'webmaster' role is defined in the test fixture
      contact = create_contact(:role => 'webmaster')
      assert_equal I18n.t('activerecord.errors.messages.taken'), contact.errors.on(:role)
    end
  end

  def test_should_not_add_when_name_is_missing
    assert_no_difference 'Contact.count' do
      contact = create_contact(:name => nil)
      assert_equal I18n.t('activerecord.errors.messages.blank'), contact.errors.on(:name)
    end
  end

  def test_should_not_add_when_role_is_missing
    assert_no_difference 'Contact.count' do
      contact = create_contact(:role => nil)
      assert_equal I18n.t('activerecord.errors.messages.blank'), contact.errors.on(:role)
    end
  end

  def test_should_not_add_when_email_is_missing
    assert_no_difference 'Contact.count' do
      contact = create_contact(:email => nil)
      assert_equal I18n.t('activerecord.errors.messages.blank'), contact.errors.on(:email)
    end
  end

  def test_should_not_add_when_email_address_is_invalid
    assert_no_difference 'Contact.count' do
      contact = create_contact(:email => 'the_zipster')
      assert_equal Authentication.bad_email_message, contact.errors.on(:email)
    end
  end

  protected

    def create_contact(options = {})
      record = Contact.new({ :role => 'zippy',
                             :name => 'Zippy the Pinhead',
                             :email => 'zippy@example.com' }.merge(options))
      record.save
      record
    end

end
