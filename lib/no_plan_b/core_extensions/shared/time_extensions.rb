module NoPlanB
  module TimeExtensions


    # Return if a date is today
    def is_today?
      self.between?(Time.now.beginning_of_day,(Time.now + 1.day).beginning_of_day)
    end

    def is_yesterday?
      self.to_date == Date.today - 1
    end

    def is_this_week?
      self.between?(Time.now.beginning_of_week,(Time.now + 1.week).beginning_of_week)
    end

    def is_this_month?
      self.between?(Time.now.beginning_of_month,(Time.now + 1.month).beginning_of_month)
    end

    def is_this_year?
      self.between?(Time.now.beginning_of_year,(s_now + 1.year).beginning_of_year)
    end

    def display_format(options = {})
      diff  = s_now - self
      if options[:full_date]
        self.strftime('%m/%d/%Y' + (options[:include_time] ? " %I:%M %p #{options[:time_zone]}" : '')).rstrip
      elsif diff.between?(0,1.minute) 
        "#{diff.to_i} secs ago"
      elsif diff.between?(0, 1.hour)
        minutes = (diff/60).to_i
        minutes.to_s + " min" + (minutes>1 ? 's' : '') + " ago"
      elsif diff.between?(0,1.minute) 
        "in #{diff.to_i} secs"
      elsif diff.between?(0, 1.hour)
        minutes = (diff/60).to_i
        "in #{minutes.to_s} min#{minutes>1 ? 's' : ''}"
      elsif self.is_today?
        self.strftime("%I:%M %p #{options[:time_zone]}").rstrip 
      elsif self.is_this_year?
        self.strftime('%b %d' + (options[:include_time] ? " %I:%M %p #{options[:time_zone]}" : '')).rstrip
      else
        self.strftime('%m/%d/%Y' + (options[:include_time] ? " %I:%M %p #{options[:time_zone]}" : '')).rstrip
      end
    end
    alias_method :sp,:display_format
    
    private

    def s_now
      Time.respond_to?(:zone) ? Time.zone.now : Time.now
    end

  end
end
