# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < ActionController::TestCase

  def test_should_show_signup_form
    get :new
    assert_response :success

    assert_select 'html > head > title', 'Create an Account'
    assert_select 'div#account-form > form[method=post]' do
      assert_select 'fieldset#account' do
        assert_select 'legend', 'Account Information'
        assert_select 'ol > li', :count => 3  # login, pw, and pw confirm
      end
      assert_select 'fieldset#personal' do
        assert_select 'legend', 'Personal Information'
        assert_select 'ol > li', :count => 2  # Name and Email
      end
    end
  end

  def test_should_show_account_info
    user = users(:quentin)
    login_as user

    get :show, :id => user.id
    assert_response :success

    assert_select 'html > head > title', "Profile for #{user.login}"
  end

  def test_should_show_account_edit_form
    user = users(:quentin)
    login_as user

    get :edit, :id => user.id
    assert_response :success

    assert_select 'html > head > title', "Edit Profile for #{user.login}"
    assert_select 'div#user-form > form[method=post] > fieldset' do
      assert_select 'legend', 'Your Details'
      assert_select 'ol > li', :count => 2  # Name and Email
    end
  end

  def test_should_update_account_info
    user = users(:quentin)
    login_as user

    put :update, :id => user.id,
                 :user => { :name => 'Number 6', :email => 'no6@mystery.gov' }
    assert_equal 'Profile updated', flash[:notice]
    assert_redirected_to user_path(user)
  end

  def test_shoud_not_update_account_with_bad_data
    user = users(:quentin)
    login_as user

    put :update, :id => user.id,
                 :user => { :email => 'nobody@nowhere' }
    assert_equal 'There was a problem updating your profile.', flash[:profile_error]
    assert_template 'edit'
  end

  def test_should_show_password_change_form
    user = users(:quentin)
    login_as user

    get :change_password, :id => user.id
    assert_response :success

    assert_select 'html > head > title', "Change Password for #{user.login}"
    assert_select 'div#password-form > form[method=post] > fieldset' do
      assert_select 'ol > li', :count => 3  # current pw, new pw, confirm pw
    end
  end

  def test_shoud_update_password
    user = users(:quentin)
    login_as user

    put :update_password, :id => user.id,
                          :user => { :current_password => 'monkey',
                                     :password => 'super-secret',
                                     :password_confirmation => 'super-secret' }
    assert_equal 'Password updated', flash[:notice]
    assert_redirected_to user_path(user)
  end

  def test_should_not_update_with_wrong_current_password
    user = users(:quentin)
    login_as user

    put :update_password, :id => user.id,
                          :user => { :current_password => 'not my real password',
                                     :password => 'super-secret',
                                     :password_confirmation => 'super-secret' }
    assert_nil User.authenticate(user.login, 'super-secret')
    assert_match /^Unable to authenticate./, flash[:password_error]
    assert_template 'change_password'
  end

  def test_should_not_update_with_invalid_new_password
    user = users(:quentin)
    login_as user

    put :update_password, :id => user.id,
                          :user => { :current_password => 'monkey',
                                     :password => 'foo',
                                     :password_confirmation => 'foo' }
    assert_nil User.authenticate(user.login, 'foo')
    assert_equal "Password #{I18n.t('activerecord.errors.messages.too_short', :count => 6)}", flash[:password_error]
    assert_template 'change_password'
  end

  def test_should_not_update_with_bad_password_confirmation
    user = users(:quentin)
    login_as user

    put :update_password, :id => user.id,
                          :user => { :current_password => 'monkey',
                                     :password => 'super-secret',
                                     :password_confirmation => 'super-sekrit' }
    assert_nil User.authenticate(user.login, 'super-secret')
    assert_equal "Password #{I18n.t('activerecord.errors.messages.confirmation')}", flash[:password_error]
    assert_template 'change_password'
  end

  def test_should_allow_signup
    assert_difference 'User.count' do
      create_user
      assert_response :redirect
    end
  end

  def test_should_require_login_on_signup
    assert_no_difference 'User.count' do
      create_user(:login => nil)
      assert assigns(:user).errors.on(:login)
      assert_response :success
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference 'User.count' do
      create_user(:password => nil)
      assert assigns(:user).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference 'User.count' do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_not_require_email_on_signup
    assert_difference 'User.count' do
      create_user(:email => nil)
      assert_nil assigns(:user).errors.on(:email)
      assert_response :redirect
    end
  end
  
  def test_should_not_require_name_on_signup
    assert_difference 'User.count' do
      create_user(:name => nil)
      assert_response :redirect
    end
  end
  
  #def should_not_allow_invalid_openid
  #  url = '\\'
  #  assert_no_difference 'User.count' do
  #    post :create, :openid_url => url
  #    assert_equal "#{url} is not an OpenID URL", flash[:openid_error]
  #    assert_response :success
  #  end
  #end

  protected

    def create_user(options = {})
      post :create, :user => { :login => 'quire',
                               :password => 'quire69',
                               :password_confirmation => 'quire69',
                               :email => 'quire@example.com',
                               :name => 'Q. U. Ire' }.merge(options)
    end

end
