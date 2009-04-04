# -*- coding: utf-8 -*-

class MainController < ApplicationController

  helper :contacts

  def index
    @contacts = Contact.to_hash

    now = Time.now.utc
    start_time = competition_data.competition_start_time_utc
    unless start_time.nil? || start_time <= now
      # Determine the timezone offset, in minutes, of the client.  If not
      # provided, default to the timezone offset defined for the competition.
      tzoffset = browser_timezone_offset || (start_time - competition_data.competition_start_time).to_i / 60

      @days_to_go = ((competition_data.competition_start_time.at_midnight.since(tzoffset*60) - now)/86400).ceil
      @event_name = competition_name
      @seconds_to_go = start_time - now
    else
      # The competition date is undefined or it's in the past
      @days_to_go = -1
      @seconds_to_go = -1
    end
  end

  def error403
    @contacts = Contact.to_hash
    render :status => 403
  end

  def error404
    @contacts = Contact.to_hash
    render :status => 404
  end

end
