# A set of methods that help format objects for displaying in the UI
module NoPlanB
  module Helpers
    module DisplayFormatHelper

      include FormatHelper
      
      # Display a time (corresponding to seconds) as time periods
      TIME_IN_SECONDS = {
        :second => 1.0,
        :minute => 60.0,
        :hour => 3600.0,
        :week => 3600*24*7.0,
        :day => 3600*24.0,
        :month => 3600*24*30.0,
        :year => 3600*24*365.0
      } unless defined? TIME_IN_SECONDS

      # Display the seconds duration in the most appropriate format of hours, minutes, and seconds depending
      # upon how long it really is
      def format_seconds_duration(seconds)
        return '' if seconds.nil?
        hrs = (seconds.to_i/3600)
        mins = (seconds.to_i/60) % 60
        secs = seconds - hrs*3600 - mins* 60
        (hrs > 0 ? ('%2d' % hrs) + ':' : '' ) +  sprintf("%02d:%02d", mins, secs) 
      end

      alias_method :display_duration, :format_seconds_duration

      def ca_time(time)
        if defined?(ActiveSupport::TimeZone)
          pst = ActiveSupport::TimeZone["Pacific Time (US & Canada)"]
          # For some reason I have to convert to float else I get some "missing method 'round'"
          time = pst.at(time.to_f)
        else  
          time = time-3.hours
        end    
      end

      def display_in_ca_time(time,options={})
        # Convert it to california time!
        # In rails 2.x the default went to GMT from system time, but we also got local timezone support
        if time = ca_time(time)
          (time.is_today? ? time.strftime("%I:%M:%S %p") : time.strftime(options[:format] || "%a %b %d %I:%M:%S %p"))  
        end
      end

      def display_age(time,options={})
        t = Time.respond_to?(:zone) ? Time.zone.now : Time.now
        display_in_time_periods(t - time,options)
      end

      def display_day(time)
        time.strftime("%a %b %d")
      end

      # WARNING - uses request parameters so a little dicey - ok for admin, I guess
      def display_time_range(from,to)
        if from || to 
          "From " + (from ? display_in_ca_time(from) : 'beginning') + " to " + (to ? display_in_ca_time(to) : 'now')
        else
          ""
        end
      end

      # Display a duration as some appropriate time periods
      # For example, a period of 37087200 is presented as:
      # >> DisplayFormatHelper.display_in_time_periods(1.years + 2.months + 4.days)
      # => 1 year 2 months 4 days 6 hours
      # NOTE: Rails adds the 6 hours to account for leap years
      # >> display_in_time_periods(1.years + 2.months + 4.days,:short => true)
      # => "1y 2m 4d 6h"
      # >> display_in_time_periods(1.years + 2.months + 4.days,:period => :months)
      # => "14.3 months"
      # >> display_in_time_periods(1.years + 2.months + 4.days,:period => :weeks)
      # => "61.3 weeks"
      # >> display_in_time_periods(1.years + 2.months + 4.days,:period => :weeks, :format => "%.0f")
      # => "61 weeks"
      # >> display_in_time_periods(1.years + 2.months + 4.days,:period => :weeks, :format => "%.2f")
      # => "61.32 weeks"
      # >> display_in_time_periods(1.years + 2.months + 4.days,:precision => 2)
      # => "1 year 2.1 months"
      # >> display_in_time_periods(1.years + 2.months + 4.days,:precision => 2, :format => "%.2f", :short => true)
      # => "1y 2.14m"
      # Options:
      #  :period => can specify any of the common periods:
      #             [:seconds,:minutes,:hours,:days,:weeks,:months,:years]
      #             if not specified, we use a mixed format
      #  :short => use short units, e.g. s for seconds, M for months, m for minutes, etc.
      #  :precision => when using the mixed format, this indicates how far to go - for example:
      #     precision 3 could be '1 year 2 months 1 week' 
      #     precision 2 would be '1 year 2.2 months'
      # precision must be > 0
      def display_in_time_periods(num,options={})
        format = options[:format] || '%.1f'
        precision = options[:precision]
        raise "precision must be an integer" if precision && precision.to_i != precision

        period = options[:period]
        case period
        when :seconds,:minutes,:hours,:days,:weeks,:months,:years 
          t_unit = period.to_s.chomp('s')
          format_period(format % (num / TIME_IN_SECONDS[t_unit.to_sym] ), t_unit,options[:short])
        else
          text = []
          accounted = 0
          first = nil
          # makes the math eaiser ....
          precision -= 1 if precision
          [:year,:month,:week,:day,:hour,:minute,:second].each_with_index { |unit,i| 
            p = TIME_IN_SECONDS[unit]
            n = (num - accounted)/ p 
            if n > 1
              accounted += (n.floor)*p
              if precision
                first ||= i
                if i - first < precision
                  n = n.floor.to_s
                elsif i - first == precision
                  n = format % n
                else
                  break
                end
              else
                n = n.floor
              end
              text << format_period(n, unit,options[:short])
            end
          }
          text*' '
        end    
      end

      def display_time_as_ago(time,options={})
        diff = Time.now - time
        suffix = ' ago'
        if diff < 0 
          diff = -diff
          suffix = ' from now'
        end
        display_in_time_periods(diff,options)+ suffix
      end 

      def date_display(date)
        date ? date.display_format(:include_time => true) : 'never'
      end

      # use the formalism of display first
      alias_method :display_date, :date_display

      def display_percent(x,y, precision=0)
        (y == 0) ? "0%" : "%3.#{precision}f%" % (x * 100.0 / y)  
      end

      def display_as_percent(x, precision=0)
        x.nil? ? "" : "%3.#{precision}f%" % (x * 100.0)  
      end

      def display_dollars(amount,options={})
        return unless amount
        if options[:prefer_whole] && amount == amount.to_i
          "$%d" % amount
        else
          "$%.2f" % amount
        end
      end

      private

      def format_period(n,unit,short=false)
        # We pluralize if it has a decimal point or it contains a decimal point
        if short
          unit == "month" ? "#{n}M" : "#{n}#{unit.to_s[0,1]}" 
        else
          pluralize = n.to_f != 1 || n.to_s.match(/\./)
          "#{n} #{unit.to_s}" + (pluralize ? 's' : '' )
        end
      end


    end

    if __FILE__ == $0
      require 'test/unit'

      class TestTime < Test::Unit::TestCase

        include DisplayFormatHelper

        def test_defined
          assert_equal "1.0 hours", display_in_time_periods(3600,:period => :hours)
          assert_equal("60.0 minutes", display_in_time_periods(3600,:period => :minutes))
          assert_equal("0.3 days", display_in_time_periods(6*3600+60,:period => :days))
          assert_equal("0.25 days", display_in_time_periods(6*3600,:period => :days,:format => '%.2f'))
          assert_equal("1.1 minutes", display_in_time_periods(66,:period => :minutes,:format => '%.1f'))
          assert_equal("1 week", display_in_time_periods(6.5*24*3600,:period => :weeks,:format => '%.0f'))
          assert_equal("1w", display_in_time_periods(6.5*24*3600,:period => :weeks,:format => '%.0f',:short => true))
          assert_equal("1M", display_in_time_periods(30.5*24*3600,:period => :months,:format => '%.0f',:short => true))
          assert_equal("1 year", display_in_time_periods(360*24*3600,:period => :years,:format => '%.0f',:short => false))
          assert_equal("7 months", display_in_time_periods(200*24*3600,:period => :months,:format => '%.0f',:short => false))
        end

        def test_precision
          t = 2*DisplayFormatHelper::TIME_IN_SECONDS[:year]+3*DisplayFormatHelper::TIME_IN_SECONDS[:month] + 3*DisplayFormatHelper::TIME_IN_SECONDS[:week] + 4*DisplayFormatHelper::TIME_IN_SECONDS[:day]
          t2 = 3*DisplayFormatHelper::TIME_IN_SECONDS[:month] + 3*DisplayFormatHelper::TIME_IN_SECONDS[:week] + 4*DisplayFormatHelper::TIME_IN_SECONDS[:day]
          t3 = 4*DisplayFormatHelper::TIME_IN_SECONDS[:day] + 6*3600
          assert_equal("2 years", display_in_time_periods(t,:precision => 1,:format => "%.0f"))
          assert_equal("2 years 4 months", display_in_time_periods(t,:precision => 2,:format => "%.0f"))
          assert_equal("2.3 years", display_in_time_periods(t,:precision => 1,:format => "%.1f"))
          assert_equal("4 months", display_in_time_periods(t2,:precision => 1,:format => "%.0f"))
          assert_equal("3.8 months", display_in_time_periods(t2,:precision => 1,:format => "%.1f"))
          assert_equal("4.25 days", display_in_time_periods(t3,:precision => 1,:format => "%.2f"))
          assert_equal("4.25d", display_in_time_periods(t3,:precision => 1,:format => "%.2f", :short => true))
        end

        def test_free
          t = 2*DisplayFormatHelper::TIME_IN_SECONDS[:year]+3*DisplayFormatHelper::TIME_IN_SECONDS[:month] + 3*DisplayFormatHelper::TIME_IN_SECONDS[:week] + 4*DisplayFormatHelper::TIME_IN_SECONDS[:day]
          t3 = 4*DisplayFormatHelper::TIME_IN_SECONDS[:day] + 6*3600
          assert_equal("2 years 3 months 3 weeks 4 days", display_in_time_periods(t))
          assert_equal("4 days 6 hours", display_in_time_periods(t3))
        end
      end

    end

  end
end