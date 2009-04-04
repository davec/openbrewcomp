# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class ContactTest < Test::Unit::TestCase

  def test_should_create_new_contact
    assert_difference 'Contact.count' do
      contact = Contact.new(:role => 'zippy',
                            :name => 'Zippy the Pinhead',
                            :email => 'zippy@example.com')
      assert contact.save
    end
  end

  def test_should_not_add_duplicate_contact
    assert_no_difference 'Contact.count' do
      # The 'webmaster' role is defined in the test fixture
      contact = Contact.new(:role => 'webmaster',
                            :name => 'the webmaster',
                            :email => 'webmaster@example.com')
      assert !contact.save
      assert_equal I18n.t('activerecord.errors.messages.taken'), contact.errors.on(:role)
    end
  end

  def test_should_not_add_when_name_is_missing
    assert_no_difference 'Contact.count' do
      contact = Contact.new(:role => 'zippy',
                            :email => 'zippy@example.com')
      assert !contact.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), contact.errors.on(:name)
    end
  end

  def test_should_not_add_when_email_address_is_invalid
    assert_no_difference 'Contact.count' do
      contact = Contact.new(:role => 'zippy',
                            :name => 'Zippy the Pinhead',
                            :email => 'the_zipster')
      assert !contact.save
      assert_equal "Email address #{I18n.t('activerecord.errors.messages.invalid')}", contact.errors.on(:base)
    end
  end

end
