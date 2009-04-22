# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class FlightTest < ActiveSupport::TestCase

  def setup
    @existing_name = flights(:light_lager_1).name
    @existing_round_id = rounds(:first).id
    @existing_award_id = awards(:LL).id
    @new_name = 'New Flight'
  end

  def test_should_create_new_flight
    assert_difference 'Flight.count' do
      flight = Flight.new(:name => @new_name,
                          :round_id => @existing_round_id,
                          :award_id => @existing_award_id)
      assert flight.save
    end
  end

  def test_should_not_create_flight_when_name_exceeds_max_length
    assert_no_difference 'Flight.count' do
      flight = Flight.new(:name => "name#{'1234567890' * 6}")
      assert !flight.save
      assert_equal I18n.t('activerecord.errors.messages.too_long', :count => 60), flight.errors.on(:name)
    end
  end

  def test_should_not_create_flight_with_missing_name
    assert_no_difference 'Flight.count' do
      flight = Flight.new(:round_id => @existing_round_id,
                          :award_id => @existing_award_id)
      assert !flight.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), flight.errors.on(:name)
    end
  end

  def test_should_not_create_flight_with_missing_round
    assert_no_difference 'Flight.count' do
      flight = Flight.new(:name => @new_name,
                          :award_id => @existing_award_id)
      assert !flight.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), flight.errors.on(:round_id)
    end
  end

  def test_should_not_create_flight_with_missing_award
    assert_no_difference 'Flight.count' do
      flight = Flight.new(:name => @new_name,
                          :round_id => @existing_round_id)
      assert !flight.save
      assert_equal I18n.t('activerecord.errors.messages.blank'), flight.errors.on(:award_id)
    end
  end

end
