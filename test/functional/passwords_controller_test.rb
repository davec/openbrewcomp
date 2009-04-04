# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'
require 'passwords_controller'

# Re-raise errors caught by the controller.
class PasswordsController; def rescue_action(e) raise e end; end

class PasswordsControllerTest < Test::Unit::TestCase
  def setup
    @controller = PasswordsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @competition_name = CompetitionData.instance.name

    # The delivery_method setting in config/environments/test.rb is no
    # longer repsected, so we're forced to set it here.
    ActionMailer::Base.delivery_method = :test

    @emails = ActionMailer::Base.deliveries
    @emails.clear
  end

  def test_should_show_reset_request_form
    get :new
    assert_response :success

    assert_select 'div#forgotten-form > form[method=post] > fieldset > legend', 'Enter Your Email Address'
  end

  def test_should_email_reset_code
    recipient = users(:aaron).email
    post :create, :password => { :email => recipient }
    assert_redirected_to new_password_path
    assert_equal "A link to change your password has been sent to #{recipient}.", flash[:notice]

    assert_equal 1, @emails.size
    email = @emails.first
    assert_equal "[#{@competition_name}] You have requested to change your password", email.subject
    assert_equal recipient, email.to[0]
    assert_match /^#{users(:aaron).login}, you can change your password at this URL:$.*^The link will expire in 3 days.$/m, email.body
  end

  def test_should_not_email_reset_code_on_unknown_email_address
    post :create, :password => { :email => 'i_do_not_exist@example.com' }
    assert_response :success
    assert_template 'new'

    assert @emails.empty?
  end

  def test_should_show_reset_form_with_valid_reset_code
    get :reset, :reset_code => passwords(:valid).reset_code
    assert_response :success

    assert_select 'div#password-reset-form > form[method=post] > fieldset > legend', 'Update Password'
  end

  def test_should_show_request_reset_form_with_invalid_reset_code
    get :reset, :reset_code => 'this_is_not_a_valid_reset_code'
    assert_redirected_to new_password_path
    assert_equal 'The change password URL you visited is either invalid or expired.', flash[:notice]
  end

  def test_should_show_request_reset_form_with_expired_reset_code
    get :reset, :reset_code => passwords(:expired).reset_code
    assert_redirected_to new_password_path
    assert_equal 'The change password URL you visited is either invalid or expired.', flash[:notice]
  end

  def test_should_update_and_redirect_to_login_page_after_accepting_new_password
    user = passwords(:valid).user
    assert_not_nil user
    post :update_after_forgetting, :user => { :password => 'new password',
                                              :password_confirmation => 'new password' },
                                   :reset_code => passwords(:valid).reset_code
    assert_equal user, User.authenticate(user.login, 'new password')
    assert_redirected_to login_path
    assert_equal 'Password was successfully updated.', flash[:notice]
  end

  def test_should_not_update_with_invalid_password
    user = passwords(:valid).user
    assert_not_nil user
    post :update_after_forgetting, :user => { :password => 'foo',
                                              :password_confirmation => 'foo' },
                                   :reset_code => passwords(:valid).reset_code
    assert_nil User.authenticate(user.login, 'new password')
    assert_redirected_to change_password_path(:reset_code => passwords(:valid).reset_code)
    assert_equal "Password #{I18n.t('activerecord.errors.messages.too_short', :count => 6)}", flash[:password_error]
  end

  def test_should_not_update_when_password_does_not_match_confirmation
    user = passwords(:valid).user
    assert_not_nil user
    post :update_after_forgetting, :user => { :password => 'new password',
                                              :password_confirmation => 'old password' },
                                   :reset_code => passwords(:valid).reset_code
    assert_nil User.authenticate(user.login, 'new password')
    assert_redirected_to change_password_path(:reset_code => passwords(:valid).reset_code)
    assert_equal "Password #{I18n.t('activerecord.errors.messages.confirmation')}", flash[:password_error]
  end

end
