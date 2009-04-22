# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::JudgeInvitesControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)

    # Since we're mucking about with the competition data in some of the
    # tests, it must be reloaded prior to each test.
    CompetitionData.reload!
    @competition_name = CompetitionData.instance.name

    ActionMailer::Base.delivery_method = :test
    @emails = ActionMailer::Base.deliveries
    @emails.clear
  end

  def test_should_show_index
    get :index
    assert_response :success

    # Validate page contents
    assert_select 'html > head > title', "Send Judge Invites"
    assert_select 'div#content' do
      assert_select 'h1', "Send Judge Invites"
      assert_select 'div#email-form > form textarea', 1
    end
  end

  def test_should_send_with_defaults
    email_count = Judge.email_count
    message = 'This is a test'

    post :send_email, :invite => { :message => message }
    assert_redirected_to :action => 'index'
    assert_equal "Spawned process to send email to #{email_count} judges.", flash[:notice]
    assert_equal email_count, @emails.size
    email1 = @emails.first
    assert_equal @competition_name, email1.subject
    assert_equal message, email1.body.strip
  end

  def test_should_send_with_subject
    email_count = Judge.email_count
    subject = 'Change the subject'
    message = 'This is a test'

    post :send_email, :invite => { :subject => subject, :message => message }
    assert_redirected_to :action => 'index'
    assert_equal "Spawned process to send email to #{email_count} judges.", flash[:notice]
    assert_equal email_count, @emails.size
    email1 = @emails.first
    assert_equal subject, email1.subject
    assert_equal message, email1.body.strip
  end

  def test_should_not_send_with_empty_message
    post :send_email, :invite => { :message => '' }
    assert_redirected_to :action => 'index'
    assert_equal 'You must provide a message', flash[:judge_invite_error]
    assert_equal 0, @emails.size
  end

  def test_should_send_to_confirmed
    target = 'confirmed'
    email_count = Judge.email_count(:target => target)
    message = 'This is a test'

    post :send_email, :invite => { :target => target, :message => message }
    assert_redirected_to :action => 'index'
    assert_equal "Spawned process to send email to #{email_count} judges.", flash[:notice]
    assert_equal email_count, @emails.size
    email1 = @emails.first
    assert_equal @competition_name, email1.subject
    assert_equal message, email1.body.strip
  end

  def test_should_send_to_unconfirmed
    target = 'unconfirmed'
    email_count = Judge.email_count(:target => target)
    message = 'This is a test'

    post :send_email, :invite => { :target => target, :message => message }
    assert_redirected_to :action => 'index'
    assert_equal "Spawned process to send email to #{email_count} judges.", flash[:notice]
    assert_equal email_count, @emails.size
    email1 = @emails.first
    assert_equal @competition_name, email1.subject
    assert_equal message, email1.body.strip
  end

  def test_index_with_no_judge_registration_dates_defined
    cd = CompetitionData.instance
    cd.judge_registration_start_time = cd.judge_registration_end_time = nil

    get :index
    assert_response :success
    assert_select 'div#content > h1 + p', 'No judge registration dates have been defined.'
  end

  def test_index_with_judge_registration_in_future
    cd = CompetitionData.instance
    cd.judge_registration_start_time = 1.day.from_now
    cd.judge_registration_end_time = 1.week.from_now

    get :index
    assert_response :success
    assert_select 'div#content > h1 + p', /^Judge registration is not yet open. Judge invites cannot be sent before /
  end

  def test_index_with_judge_registration_in_past
    cd = CompetitionData.instance
    cd.judge_registration_start_time = 1.week.ago
    cd.judge_registration_end_time = 1.day.ago

    get :index
    assert_response :success
    assert_select 'div#content > h1 + p', /^Judge registration closed /
  end

  def test_index_with_no_judges
    Score.destroy_all
    Judging.destroy_all
    Judge.destroy_all

    get :index
    assert_response :success
    assert_select 'div#content > h1 + p', 'No judge email addresses could be found.'
  end

end
