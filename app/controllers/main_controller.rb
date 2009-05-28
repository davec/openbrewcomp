# -*- coding: utf-8 -*-

class MainController < ApplicationController

  helper :contacts

  def index
    @contacts = Contact.to_hash

    now = Time.now.utc
    start_time = competition_data.competition_start_time_utc
    @days_to_go = unless start_time.nil? || start_time <= now
      # Determine the timezone offset, in minutes, of the client.  If not
      # provided, default to the timezone offset defined for the competition.
      tzoffset = browser_timezone_offset || (start_time - competition_data.competition_start_time).to_i / 60

      (competition_data.competition_start_time.to_date - (now - tzoffset*60).to_date).to_i
    else
      # The competition date is undefined or it's in the past
      -1
    end
  end

  [ 403, 404, 500 ].each do |status|
    class_eval %{
      def error#{status}
        @contacts = Contact.to_hash
        render :status => #{status}
      end
    }, __FILE__, __LINE__
  end

end
