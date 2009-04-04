# -*- coding: utf-8 -*-

require 'rational'

module TimeInterval

  # Computes the difference, in words, between two time values.
  #
  # +source+ and +destination+ may be a non-nil Date, DateTime, or Time object.
  # The <tt>:seconds</tt> option may be set to <tt>true</tt> in the +options+
  # to include the seconds in # the results; the default is to omit the seconds
  # and, in the case of a time difference of less than 1 minute, to return the
  # string <tt>less than a minute</tt>.
  def self.difference_in_words(start_time, end_time, options = {})
    return nil if start_time.nil? || end_time.nil?
    anchor = if start_time.is_a?(Date)
               start_time
             elsif start_time.is_a?(Time)
               DateTime.new(*start_time.dup.utc.to_a[0,6].reverse)
             else
               # uninitialized constant ArgumentException?  WTF
               #raise ArgumentException, "start_time parameter must be a Date, DateTime, or Time object"
               raise 'invalid argument type'
             end
    target = if end_time.is_a?(Date)
               end_time
             elsif end_time.is_a?(Time)
               DateTime.new(*end_time.dup.utc.to_a[0,6].reverse)
             else
               # uninitialized constant ArgumentException?  WTF
               #raise ArgumentException, "end_time parameter must be a Date, DateTime, or Time object"
               raise 'invalid argument type'
             end

    TimeInterval.interval_in_words(target - anchor, options)
  end

  def self.interval_in_words(interval, options = {})
    fractional_days = if interval.is_a?(Rational)
                        interval
                      elsif interval.is_a?(Numeric)
                        Rational(interval.to_i, 1.day)
                      else
                        raise 'invalid argument type'
                      end
    days = fractional_days.to_i
    hours, minutes, seconds, ignore = Date.day_fraction_to_time(fractional_days - days)

    return (options[:seconds] ? ActionView::Helpers::TextHelper.pluralize(seconds, 'second') : "less than a minute") if [ days, hours, minutes ] == [ 0, 0, 0 ]

    seconds = 0 unless options[:seconds]
    parts = []
    parts << ActionView::Helpers::TextHelper.pluralize(days, 'day') unless days == 0
    unless [ hours, minutes, seconds ] == [ 0, 0, 0 ]
      parts << ActionView::Helpers::TextHelper.pluralize(hours, 'hour') unless [ days, hours ] == [ 0, 0 ]
      unless [ minutes, seconds ] == [ 0, 0 ]
        parts << ActionView::Helpers::TextHelper.pluralize(minutes, 'minute')
        parts << ActionView::Helpers::TextHelper.pluralize(seconds, 'second') if options[:seconds]
      end
    end

    parts.to_sentence
  end

end
