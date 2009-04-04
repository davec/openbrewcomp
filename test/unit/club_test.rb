# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class ClubTest < Test::Unit::TestCase

  def setup
    @existing_club = clubs(:rangers).name
    @new_club = 'BREW'
  end

  def test_should_create_new_club
    assert_difference 'Club.count' do
      club = Club.new(:name => @new_club)
      assert club.save
    end
  end

  def test_should_not_add_duplicate_club
    assert_no_difference 'Club.count' do
      club = Club.new(:name => @existing_club)
      assert !club.save
      assert_equal 'already exists', club.errors.on(:name)
    end
  end

  def test_should_not_add_when_name_differs_only_in_case
    assert_no_difference 'Club.count' do
      club = Club.new(:name => @existing_club.downcase)
      assert !club.save
      assert_equal 'already exists', club.errors.on(:name)
    end
  end

  def test_should_not_add_when_name_differs_only_in_whitespace
    assert_no_difference 'Club.count' do
      club = Club.new(:name => " #{@existing_club.gsub(' ', '   ')} ")
      assert !club.save
      assert_equal 'already exists', club.errors.on(:name)
    end
  end

  def test_should_not_add_when_name_exceeds_max_length
    assert_no_difference 'Club.count' do
      club = Club.new(:name => "club_#{'1234567890' * 6}")
      assert !club.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 60), club.errors.on(:name)
    end
  end

  def test_should_not_add_when_missing_club_name
    assert_no_difference 'Club.count' do
      club = Club.new
      assert !club.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), club.errors.on(:name)
    end
  end

end
