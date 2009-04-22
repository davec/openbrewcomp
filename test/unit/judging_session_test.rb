# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class JudgingSessionTest < ActiveSupport::TestCase

  def setup
    @date = Time.now.to_date.to_s
    @existing_session_description = judging_sessions(:second).description
    @new_session_description = 'A New Judging Session'
  end

  def test_should_create_new_session
    assert_difference 'JudgingSession.count' do
      session = JudgingSession.new(:description => @new_session_description,
                                   :date => @date,
                                   :position => 0)
      assert session.save
    end
  end

  def test_should_not_create_when_description_only_differs_in_case
    assert_no_difference 'JudgingSession.count' do
      session = JudgingSession.new(:description => @existing_session_description.downcase,
                                   :date => @date,
                                   :position => 9)
      assert !session.save
      assert_equal 'already exists', session.errors.on(:description)
    end
  end

  def test_should_not_create_when_description_only_differs_in_whitespace
    assert_no_difference 'JudgingSession.count' do
      session = JudgingSession.new(:description => " #{@existing_session_description.gsub(' ','   ')} ",
                                   :date => @date,
                                   :position => 9)
      assert !session.save
      assert_equal 'already exists', session.errors.on(:description)
    end
  end

  def test_should_not_create_with_duplicate_description
    assert_no_difference 'JudgingSession.count' do
      session = JudgingSession.new(:description => @existing_session_description,
                                   :date => @date,
                                   :position => 9)
      assert !session.save
      assert_equal 'already exists', session.errors.on(:description)
    end
  end

  def test_should_not_create_when_description_exceeds_max_length
    assert_no_difference 'JudgingSession.count' do
      session = JudgingSession.new(:description => "This is too long #{'1234567890' * 25}",
                                   :date => @date,
                                   :position => 9)
      assert !session.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 255), session.errors.on(:description)
    end
  end

  def test_should_not_create_when_missing_description
    assert_no_difference 'JudgingSession.count' do
      session = JudgingSession.new(:date => @date,
                                   :position => 9)
      assert !session.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), session.errors.on(:description)
    end
  end

  def test_should_not_create_when_missing_date
    assert_no_difference 'JudgingSession.count' do
      session = JudgingSession.new(:description => @new_session_description,
                                   :position => 9)
      assert !session.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), session.errors.on(:date)
    end
  end

  def test_should_create_when_missing_position_and_append_to_list
    expected_position = JudgingSession.maximum(:position) + 1
    assert_difference 'JudgingSession.count' do
      session = JudgingSession.new(:description => @new_session_description,
                                   :date => @date)
      assert session.save
      assert_equal expected_position, session.position
    end
  end

  def test_not_create_when_start_time_is_after_end_time
    assert_no_difference 'JudgingSession.count' do
      session = JudgingSession.new(:description => @new_session_description,
                                   :date => @date,
                                   :start_time => 6.hours.from_now.to_s(:db),
                                   :end_time => 1.hour.from_now.to_s(:db))
      assert !session.save
      assert_equal 'The start time must be earlier than the end time.', session.errors.on(:base)
    end
  end

  def test_should_create_with_start_time_and_no_end_time
    assert_difference 'JudgingSession.count' do
      session = JudgingSession.new(:description => @new_session_description,
                                   :date => @date,
                                   :start_time => 1.hour.from_now.to_s(:db))
      assert session.save
    end
  end

  def test_should_create_with_end_time_and_no_start_time
    assert_difference 'JudgingSession.count' do
      session = JudgingSession.new(:description => @new_session_description,
                                   :date => @date,
                                   :end_time => 6.hours.from_now.to_s(:db))
      assert session.save
    end
  end

end
