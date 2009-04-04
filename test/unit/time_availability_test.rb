# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class TimeAvailabilityTest < ActiveSupport::TestCase

  def test_should_create_new_record
    assert_difference 'TimeAvailability.count' do
      t = create_record
      assert !t.new_record?, "#{t.errors.full_messages.to_sentence}"
    end
  end

  def test_should_not_create_when_start_time_is_after_end_time
    assert_no_difference 'TimeAvailability.count' do
      t = create_record(:start_time => Date.tomorrow,
                        :end_time => Date.yesterday)
      assert_equal 'Start time must be earlier than end time', t.errors.on(:base)
    end
  end

  def test_should_not_create_with_nil_start_time
    assert_no_difference 'TimeAvailability.count' do
      t = create_record(:start_time => nil)
      assert_equal I18n.t('activerecord.errors.messages.blank'), t.errors.on(:start_time)
    end
  end

  def test_should_not_create_with_nil_end_time
    assert_no_difference 'TimeAvailability.count' do
      t = create_record(:end_time => nil)
      assert_equal I18n.t('activerecord.errors.messages.blank'), t.errors.on(:end_time)
    end
  end

  protected

    def create_record(options = {})
      record = TimeAvailability.new({ :judge_id => judges(:certified_judge).id,
                                      :start_time => Date.yesterday,
                                      :end_time => Date.tomorrow }.merge(options))
      record.save
      record
    end

end
