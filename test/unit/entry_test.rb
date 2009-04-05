# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class EntryTest < Test::Unit::TestCase

  def setup
    @good_entrant_id = entrants(:Team1).id
    @good_user_id = users(:admin).id
    @first_time_id = styles(:first_time).id
  end

  def test_should_create_new_entry
    assert_difference 'Entry.count' do
      entry = Entry.new(:style_id => styles(:style_1B).id,
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert entry.save
      ## This doesn't work in the test environment now that we're using foxy
      # fixtures because the entry IDs are large integers (>10000).
      #expected_registration_code = sprintf('%d%0.4d', Date.today.year, entry.id).to_i
      #assert_equal expected_registration_code, entry.registration_code
      assert !entry.registration_code.blank?
    end
  end

  def test_should_not_create_null_entry
    assert_no_difference 'Entry.count' do
      entry = Entry.new()
      assert !entry.save
      assert_included 'A style must be specified', entry.errors.on(:base)
    end
  end

  def test_should_not_create_entry_without_style
    assert_no_difference 'Entry.count' do
      entry = Entry.new(:entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert !entry.save
      assert_included 'A style must be specified', entry.errors.on(:base)
    end
  end

  def test_should_create_entry_with_required_styleinfo
    assert_difference 'Entry.count' do
      entry = Entry.new(:style_id => styles(:style_20).id,
                        :style_info => 'Style info',
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert entry.save
    end
  end

  def test_should_not_create_entry_with_missing_required_styleinfo
    assert_no_difference 'Entry.count' do
      entry = Entry.new(:style_id => styles(:style_20).id,
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert !entry.save
      assert_included 'Style information must be specified', entry.errors.on(:base)
    end
  end

  def test_should_create_entry_with_classic_style
    assert_difference 'Entry.count' do
      entry = Entry.new(:style_id => styles(:style_20).id,
                        :classic_style_id => styles(:style_6A).id,
                        :style_info => 'Style info',
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert entry.save
      assert_equal styles(:style_6A).id, entry.base_style.id
    end
  end

  def test_should_not_create_entry_with_invalid_classic_style
    assert_no_difference 'Entry.count' do
      entry = Entry.new(:style_id => styles(:style_20).id,
                        :classic_style_id => styles(:style_23).id,
                        :style_info => 'Style info',
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert !entry.save
      assert_equal "#{I18n.t('activerecord.errors.messages.invalid')}", entry.errors.on(:classic_style)
    end
  end

  def test_should_create_mead_entry
    assert_difference 'Entry.count' do
      entry = Entry.new(:style_id => styles(:style_24A).id,
                        :carbonation_id => carbonation(:still).id,
                        :strength_id => strength(:standard).id,
                        :style_info => 'Style info',
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert entry.save
    end
  end

  def test_should_not_create_mead_entry_with_mismatched_info
    assert_no_difference 'Entry.count' do
      entry = Entry.new(:style_id => styles(:style_24A).id,
                        :sweetness_id => sweetness(:sweet).id,
                        :carbonation_id => carbonation(:still).id,
                        :strength_id => strength(:standard).id,
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert !entry.save
      assert_equal 'must be dry', entry.errors.on(:sweetness)
    end
  end

  def test_should_not_create_mead_entry_with_missing_info
    assert_no_difference 'Entry.count' do
      entry = Entry.new(:style_id => styles(:style_25A).id,
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert !entry.save
      assert_included 'The sweetness level must be specified', entry.errors.on(:base)
      assert_included 'The carbonation level must be specified', entry.errors.on(:base)
      assert_included 'The strength level must be specified', entry.errors.on(:base)
    end
  end

  def test_should_create_entry_with_no_first_time_style_defined
    Style.destroy(@first_time_id)
    assert_difference 'Entry.count' do
      entry = Entry.new(:style_id => styles(:style_7A).id,
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert entry.save
    end
  end

  def test_should_create_first_time_entry_with_base_style
    assert_difference 'Entry.count' do
      entry = Entry.new(:style_id => @first_time_id,
                        :base_style_id => styles(:style_10A).id,
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert entry.save
    end
  end

  def test_should_create_first_time_entry_with_required_styleinfo
    assert_difference 'Entry.count' do
      entry = Entry.new(:style_id => @first_time_id,
                        :base_style_id => styles(:style_20).id,
                        :style_info => 'Style info',
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert entry.save
      assert_equal styles(:style_20).id, entry.base_style_id
    end
  end

  def test_should_not_create_first_time_entry_with_missing_required_styleino
    assert_no_difference 'Entry.count' do
      entry = Entry.new(:style_id => @first_time_id,
                        :base_style_id => styles(:style_20).id,
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert !entry.save
      assert_included 'Style information must be specified', entry.errors.on(:base)
    end
  end

  def test_should_not_create_first_time_entry_with_missing_base_style
    assert_no_difference 'Entry.count' do
      entry = Entry.new(:style_id => @first_time_id,
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert !entry.save
      assert_included 'A base style must be specified', entry.errors.on(:base)
    end
  end

  def test_should_not_create_first_time_entry_with_invalid_base_style
    assert_no_difference 'Entry.count' do
      entry = Entry.new(:style_id => @first_time_id,
                        :base_style_id => styles(:special).id,
                        :style_info => 'Style info',
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert !entry.save
      assert_equal "#{I18n.t('activerecord.errors.messages.invalid')}", entry.errors.on(:base_style)
    end
  end

  def test_should_create_first_time_mead_entry
    assert_difference 'Entry.count' do
      entry = Entry.new(:style_id => @first_time_id,
                        :base_style_id => styles(:style_25C).id,
                        :sweetness_id => sweetness(:medium).id,
                        :carbonation_id => carbonation(:still).id,
                        :strength_id => strength(:standard).id,
                        :style_info => 'Style info',
                        :entrant_id => @good_entrant_id,
                        :user_id => @good_user_id)
      assert entry.save
    end
  end

end
