# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class CompetitionDataTest < Test::Unit::TestCase

  def setup
    CompetitionData.reload!
  end

  def test_singleton_behavior
    cd1 = CompetitionData.instance
    cd2 = CompetitionData.instance

    # Verify that cd1 and cd2 are the same object
    assert_equal cd1.object_id, cd2.object_id

    # Change the name in cd1 and verify that it's also changed in cd2
    new_name = "#{cd1.name} (extended)"
    cd1.name = new_name
    assert_equal new_name, cd2.name

    # Save the change, get the data directly from the database via find_by_sql,
    # and verify that the new name was saved in the database.
    cd1.save
    cd3 = CompetitionData.find_by_sql('SELECT * FROM competition_data')[0]
    assert_equal new_name, cd3.name
    assert_not_equal cd1.object_id, cd3.object_id

    # Get the data via find and verify that it's the same as the original
    # cd1 object above.
    cd4 = CompetitionData.find(:first)
    assert_equal cd1.object_id, cd4.object_id
  end

  def test_should_not_allow_new
    assert_raise(NoMethodError, "Attempt to call private method `new' for CompetitionData class.") {
      cd = CompetitionData.new(:name => 'A record that cannot be added')
    }
  end

  def test_should_not_allow_create
    assert_raise(RuntimeError, 'Only one competition data record is allowed.') {
      cd = CompetitionData.create(:name => 'A record that cannot be added')
    }
  end

  def test_should_not_allow_clone
    cd = CompetitionData.instance
    assert_raise(TypeError, 'Cannot clone a CompetitionData object') {
      cd2 = cd.clone
    }
  end

  def test_should_not_allow_dup
    cd = CompetitionData.instance
    assert_raise(TypeError, 'Cannot dup a CompetitionData object') {
      cd2 = cd.dup
    }
  end

  def test_should_not_allow_delete
    # Verify that there is only one record in the existing table
    assert_equal(1, CompetitionData.count)

    # Get the record and attempt to delete it
    cd = CompetitionData.instance
    assert_raise(RuntimeError, 'Deletion is not allowed') { cd.destroy }
  end

  def test_should_update_with_nil_timezone
    cd = CompetitionData.instance
    cd.local_timezone = nil
    assert cd.save
  end

  def test_should_not_update_with_invalid_timezone
    cd = CompetitionData.instance
    cd.local_timezone = 'Etc/Invalid'
    assert !cd.save
    assert_equal I18n.t('activerecord.errors.messages.invalid'), cd.errors.on(:local_timezone)
  end

  def test_should_not_update_with_name_too_long
    cd = CompetitionData.instance
    cd.name = "This is too long #{'1234567890' * 25}"
    assert !cd.save
    assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 255), cd.errors.on(:name)
  end

  def test_should_not_update_with_invalid_competition_number
    cd = CompetitionData.instance
    cd.competition_number = 42
    assert !cd.save
    assert_equal 'must be a 6 digit value, 100000 or greater', cd.errors.on(:competition_number)
  end

  def test_should_update_with_nil_competition_number
    cd = CompetitionData.instance
    cd.competition_number = nil
    assert cd.save
  end

  def test_should_update_with_nil_competition_date
    cd = CompetitionData.instance
    cd.competition_date = nil
    assert cd.save
    #assert !cd.save
    #assert_equal I18n.t('activerecord.errors.messages.blank'), cd.errors.on(:competition_date)
  end

  def test_should_update_with_nil_competition_start_time
    cd = CompetitionData.instance
    cd.competition_start_time_utc = nil
    assert cd.save
    #assert !cd.save
    #assert_equal I18n.t('activerecord.errors.messages.blank'), cd.errors.on(:competition_start_time)
  end

  def test_string_time_values_in_utc
    start_time = 2.weeks.ago.utc
    end_time = 2.weeks.from_now.utc
    cd = CompetitionData.instance
    cd.local_timezone = 'UTC'
    cd.entry_registration_start_time_utc = start_time.to_s
    cd.entry_registration_end_time_utc = end_time.to_s
    assert cd.save
    # Note: Integer time values are compared because the original times,
    # based on Time.now, contain fractional seconds but the "massaged" times
    # stored in the CompetitionData object do not.
    assert_equal start_time.localtime.to_i, cd.entry_registration_start_time.to_i
    assert_equal end_time.localtime.to_i, cd.entry_registration_end_time.to_i
    assert_equal start_time.to_i, cd.entry_registration_start_time_utc.to_i
    assert_equal end_time.to_i, cd.entry_registration_end_time_utc.to_i
  end

  def test_should_not_update_when_entry_registration_start_time_is_after_entry_registration_end_time
    cd = CompetitionData.instance
    cd.entry_registration_start_time_utc = 1.day.from_now.utc
    cd.entry_registration_end_time_utc = 1.day.ago.utc
    cd.local_timezone = 'UTC'
    assert !cd.save
    assert_equal 'The entry registration start time must be earlier than the entry registration end time', cd.errors.on(:base)
  end

  def test_should_update_with_nil_entry_registration_start_time
    cd = CompetitionData.instance
    cd.entry_registration_start_time_utc = 1.day.ago.utc
    cd.entry_registration_end_time_utc = nil
    cd.local_timezone = 'UTC'
    assert cd.save
  end

  def test_should_update_with_nil_entry_registration_end_time
    cd = CompetitionData.instance
    cd.entry_registration_start_time_utc = nil
    cd.entry_registration_end_time_utc = 1.day.from_now.utc
    cd.local_timezone = 'UTC'
    assert cd.save
  end

  def test_should_not_update_with_entry_registration_start_time_and_entry_registration_end_time_both_nil
    cd = CompetitionData.instance
    cd.entry_registration_start_time_utc = nil
    cd.entry_registration_end_time_utc = nil
    cd.local_timezone = 'UTC'
    assert cd.save!
  end

  def test_status_entry_open
    cd = CompetitionData.instance
    cd.local_timezone = "Etc/GMT#{'%+d' %(Time.now.gmt_offset/3600)}"
    cd.entry_registration_start_time = 1.hour.ago
    cd.entry_registration_end_time = 1.hour.from_now

    assert cd.is_entry_registration_open?
    assert !cd.is_entry_registration_future?
    assert !cd.is_entry_registration_past?
  end

  def test_status_entry_future
    cd = CompetitionData.instance
    cd.local_timezone = "Etc/GMT#{'%+d' %(Time.now.gmt_offset/3600)}"
    cd.entry_registration_start_time = 1.hour.from_now
    cd.entry_registration_end_time = 1.day.from_now

    assert !cd.is_entry_registration_open?
    assert cd.is_entry_registration_future?
    assert !cd.is_entry_registration_past?
  end

  def test_status_entry_past
    cd = CompetitionData.instance
    cd.local_timezone = "Etc/GMT#{'%+d' %(Time.now.gmt_offset/3600)}"
    cd.entry_registration_start_time = 1.day.ago
    cd.entry_registration_end_time = 1.hour.ago

    assert !cd.is_entry_registration_open?
    assert !cd.is_entry_registration_future?
    assert cd.is_entry_registration_past?
  end

  def test_should_not_update_when_judge_registration_start_time_is_after_judge_registration_end_time
    cd = CompetitionData.instance
    cd.judge_registration_start_time_utc = 1.day.from_now.utc
    cd.judge_registration_end_time_utc = 1.day.ago.utc
    cd.local_timezone = 'UTC'
    assert !cd.save
    assert_equal 'The judge registration start time must be earlier than the judge registration end time', cd.errors.on(:base)
  end

  def test_should_update_with_nil_judge_registration_start_time
    cd = CompetitionData.instance
    cd.judge_registration_start_time_utc = 1.day.ago.utc
    cd.judge_registration_end_time_utc = nil
    cd.local_timezone = 'UTC'
    assert cd.save
  end

  def test_should_update_with_nil_judge_registration_end_time
    cd = CompetitionData.instance
    cd.judge_registration_start_time_utc = nil
    cd.judge_registration_end_time_utc = 1.day.from_now.utc
    cd.local_timezone = 'UTC'
    assert cd.save
  end

  def test_should_not_update_with_judge_registration_start_time_and_judge_registration_end_time_both_nil
    cd = CompetitionData.instance
    cd.judge_registration_start_time_utc = nil
    cd.judge_registration_end_time_utc = nil
    cd.local_timezone = 'UTC'
    assert cd.save!
  end

  def test_status_judge_open
    cd = CompetitionData.instance
    cd.local_timezone = "Etc/GMT#{'%+d' %(Time.now.gmt_offset/3600)}"
    cd.judge_registration_start_time = 1.hour.ago
    cd.judge_registration_end_time = 1.hour.from_now

    assert cd.is_judge_registration_open?
    assert !cd.is_judge_registration_future?
    assert !cd.is_judge_registration_past?
  end

  def test_status_judge_future
    cd = CompetitionData.instance
    cd.local_timezone = "Etc/GMT#{'%+d' %(Time.now.gmt_offset/3600)}"
    cd.judge_registration_start_time = 1.hour.from_now
    cd.judge_registration_end_time = 1.day.from_now

    assert !cd.is_judge_registration_open?
    assert cd.is_judge_registration_future?
    assert !cd.is_judge_registration_past?
  end

  def test_status_judge_past
    cd = CompetitionData.instance
    cd.local_timezone = "Etc/GMT#{'%+d' %(Time.now.gmt_offset/3600)}"
    cd.judge_registration_start_time = 1.day.ago
    cd.judge_registration_end_time = 1.hour.ago

    assert !cd.is_judge_registration_open?
    assert !cd.is_judge_registration_future?
    assert cd.is_judge_registration_past?
  end

  def test_timezone_change_adjusts_utc_times
    cd = CompetitionData.instance
    # The initial timezone is supposed to be UTC so the local and UTC times
    # should be equal.
    assert_equal cd.competition_start_time, cd.competition_start_time_utc

    # Now, we'll change the timezone from UTC to GMT-6 which should leave
    # the local time unchanged and advance the UTC time by 6 hours.
    original_local_competition_start_time = cd.competition_start_time.dup
    cd.local_timezone = 'Etc/GMT-6'
    assert_equal 6.0, (cd.competition_start_time_utc - cd.competition_start_time)/3600.0
    assert_equal original_local_competition_start_time, cd.competition_start_time
  end

end
