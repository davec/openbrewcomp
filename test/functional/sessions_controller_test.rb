# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'
require 'sessions_controller'

# Re-raise errors caught by the controller.
class SessionsController; def rescue_action(e) raise e end; end

class SessionsControllerTest < ActionController::TestCase

  def test_should_login_and_redirect
    post :create, :user => { :login => 'quentin', :password => 'monkey' }
    assert session[:user_id]
    assert_response :redirect
  end

  def test_should_login_anonymously
    post :create, :anonymous => '1'
    assert session[:user_id]
    assert_response :redirect
    assert @controller.send(:current_user).is_anonymous?
  end

  def test_should_update_last_logon
    last_logon = users(:quentin).last_logon_at
    post :create, :user => { :login => 'quentin', :password => 'monkey' }
    assert_not_equal(last_logon, @controller.send(:current_user).last_logon_at)
    assert_in_delta(Time.now.utc.to_f, @controller.send(:current_user).last_logon_at.to_f, 1.0)
  end

  def test_should_fail_login_and_not_redirect
    post :create, :user => { :login => 'quentin', :password => 'bad password' }
    assert_nil session[:user_id]
    assert_response :success
  end

  def test_should_logout
    login_as :quentin
    get :destroy
    assert_nil session[:user_id]
    assert_response :redirect
  end

  def test_should_remember_me
    @request.cookies["auth_token"] = nil
    post :create, :user => { :login => 'quentin', :password => 'monkey' }, :remember_me => '1'
    assert_not_nil @response.cookies["auth_token"]
  end

  def test_should_not_remember_me
    @request.cookies["auth_token"] = nil
    post :create, :user => { :login => 'quentin', :password => 'monkey' }, :remember_me => '0'
    puts @response.cookies["auth_token"]
    assert @response.cookies["auth_token"].blank?
  end
  
  def test_should_delete_token_on_logout
    login_as :quentin
    get :destroy
    assert @response.cookies["auth_token"].blank?
  end

  def test_should_login_with_cookie
    users(:quentin).remember_me
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    assert @controller.send(:logged_in?)
  end

  def test_should_fail_expired_cookie_login
    users(:quentin).remember_me
    users(:quentin).update_attribute :remember_token_expires_at, 5.minutes.ago
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    assert !@controller.send(:logged_in?)
  end

  def test_should_fail_cookie_login
    users(:quentin).remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :new
    assert !@controller.send(:logged_in?)
  end

  #def should_not_allow_invalid_openid
  #  url = '\\'
  #  post :create, :openid_url => url
  #  assert_nil session[:user_id]
  #  assert_equal "#{url} is not an OpenID URL", flash[:openid_error]
  #  assert_response :success
  #end

  protected

    def auth_token(token)
      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
    end
    
    def cookie_for(user)
      auth_token users(user).remember_token
    end

end
