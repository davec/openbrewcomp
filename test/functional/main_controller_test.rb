# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class MainControllerTest < ActionController::TestCase

  include ActionView::Helpers::TextHelper

  def test_index
    get :index
    assert_response :success
  end

  def test_index_with_varying_competition_start_times
    now = Time.now
    hours_til_tomorrow = ((Date.tomorrow.to_time - now) / 3600).ceil
    gmt_offset = now.gmt_offset  # In seconds
    server_timezone_cookie_value = gmt_offset/-60  # In "reversed" minutes
    cd = CompetitionData.instance
    cd.local_timezone = "Etc/GMT#{'%+d' % (-gmt_offset/3600)}"  # In hours

    # We need to test at least two different clients, residing in different
    # calendar days (i.e., if the local day is May 1, we need another client
    # whose local day is May 2).

    start_times = [
      Time.today + 1.week + 12.hours,  # One week from now @ noon (local time)
      Time.today + 1.day  + 12.hours,  # One day from now @ noon (local time)
      Time.today - 1.week + 12.hours,  # One week ago
    ]
    local_dates = {
      hours_til_tomorrow     => start_times.zip([ 6, 0, 0 ]), # After midnight local time
      hours_til_tomorrow - 1 => start_times.zip([ 7, 1, 0 ]), # Before midnight local time
      0                      => start_times.zip([ 7, 1, 0 ])  # Current timezone
    }

    local_dates.each do |adjust, values|
      @request.cookies['TZ'] = CGI::Cookie.new('TZ', "#{server_timezone_cookie_value - adjust*60}")
      values.each do |pair|
        cd.competition_start_time, days_to_go = pair
        expected_opening_message = "#{pluralize(days_to_go, 'day')} until #{cd.name}"
        get :index
        assert_response :success
        if days_to_go > 0
          assert_select "div#countdown", expected_opening_message
        else
          assert_select "div#countdown", 0
        end
      end
    end
  end

end
