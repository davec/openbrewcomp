# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase

  def test_should_create_user
    assert_difference 'User.count' do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  def test_should_not_accept_duplicate_login
    # The 'admin' user is defined in the test fixture
    assert_no_difference 'User.count' do
      user = create_user(:login => 'admin')
      assert_equal I18n.t('activerecord.errors.messages.taken'), user.errors.on(:login)
    end
  end

  def test_should_not_accept_login_too_short
    assert_no_difference 'User.count' do
      user = create_user(:login => 'me')
      assert_equal I18n.t('activerecord.errors.messages.too_short', :count => 3), user.errors.on(:login)
    end
  end

  def test_should_not_accept_login_too_long
    assert_no_difference 'User.count' do
      user = create_user(:login => "user#{'1234567890' * 4}")
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 40), user.errors.on(:login)
    end
  end

  def test_should_not_accept_password_too_short
    assert_no_difference 'User.count' do
      user = create_user(:password => 'pw',
                         :password_confirmation => 'pw')
      assert_equal I18n.t('activerecord.errors.messages.too_short', :count => 6), user.errors.on(:password)
    end
  end

  def test_should_not_accept_password_too_long
    assert_no_difference 'User.count' do
      user = create_user(:password => "password#{'1234567890' *4}",
                         :password_confirmation => "password#{'1234567890' *4}")
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 40), user.errors.on(:password)
    end
  end

  def test_should_require_password
    assert_no_difference 'User.count' do
      user = create_user(:password => nil)
      assert user.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference 'User.count' do
      user = create_user(:password_confirmation => nil)
      assert user.errors.on(:password_confirmation)
    end
  end

  def test_should_not_allow_password_and_username_identical
    assert_no_difference 'User.count' do
      user = create_user(:login => 'blotto',
                         :password => 'blotto',
                         :password_confirmation => 'blotto')
      assert_equal 'cannot be the same as your login name', user.errors.on(:password)
    end
  end

  def test_should_not_allow_password_and_username_reversed
    assert_no_difference 'User.count' do
      user = create_user(:login => 'blotto',
                         :password => 'ottolb',
                         :password_confirmation => 'ottolb')
      assert_equal 'cannot be the reverse of your login name', user.errors.on(:password)
    end
  end

  def test_should_not_delete_admin
    assert_raise(RuntimeError, 'The admin account cannot be deleted.') do
      users(:admin).destroy
    end
  end

  def test_should_not_accept_invalid_email_address
    assert_no_difference 'User.count' do
      user = create_user(:email => 'user@domain')
      assert_equal Authentication.bad_email_message, user.errors.on(:email)
    end
  end

  def test_should_reset_password
    users(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:quentin), User.authenticate('quentin', 'new password')
  end

  def test_should_not_rehash_password
    users(:quentin).update_attributes(:login => 'quentin2')
    assert_equal users(:quentin), User.authenticate('quentin2', 'monkey')
  end

  def test_should_authenticate_user
    assert_equal users(:quentin), User.authenticate('quentin', 'monkey')
  end

  def test_should_set_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
  end

  def test_should_unset_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    users(:quentin).forget_me
    assert_nil users(:quentin).remember_token
  end

  def test_should_remember_me_for_one_week
    before = 1.week.from_now.utc
    users(:quentin).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    users(:quentin).remember_me_until time
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert_equal users(:quentin).remember_token_expires_at, time
  end

  def test_should_remember_me_default_two_weeks
    before = 2.weeks.from_now.utc
    users(:quentin).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end

  def test_should_delete_user
    assert_difference('User.count', -1) do
      users(:quentin).destroy
    end
  end

  def test_should_restrict_login_characters
    assert_no_difference 'User.count' do
      user = create_user(:login => '|pipe>')
      assert_equal Authentication.bad_login_message, user.errors.on(:login)
    end
  end

  def test_case_sensitivity
    login = 'MixedCaseUser'
    password = 'MixedCasePassword'
    assert_difference 'User.count' do
      user = create_user(:login => login,
                         :password => password,
                         :password_confirmation => password)

      # Check that the login name is not case-sensitive
      user_lc = User.authenticate(login.downcase, password)
      assert_not_nil user_lc

      # Check that the password is case-sensitive
      user_pass_lc = User.authenticate(login.downcase, password.downcase)
      assert_nil user_pass_lc
    end
  end

  protected

    def create_user(options = {})
      record = User.new({ :login => 'quire',
                          :email => 'quire@example.com',
                          :password => 'quire69',
                          :password_confirmation => 'quire69',
                          :name => 'Q. U. Ire' }.merge(options))
      record.save
      record
    end

end
