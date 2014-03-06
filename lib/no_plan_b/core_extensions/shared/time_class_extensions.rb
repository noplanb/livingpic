module NoPlanB
  module TimeClassExtensions
    require 'rubygems'
    require 'action_view'
    include ActionView::Helpers::TextHelper
    
    def approx_duration_display(duration_in_seconds)
      d = duration_in_seconds
      if d.between?(0,1.minute)
        "less than 1 minute"
      elsif d.between?(0, 1.hour)
        pluralize(d.div(1.minute), 'minute')
      elsif d.between?(0, 1.day)
        pluralize(d.div(1.hour), 'hour')
      else 
        t = pluralize(d.div(1.day), 'day')
        t +=  " " + pluralize((d % 1.day).div(1.hour), 'hour') if (d % 1.day).div(1.hour) != 0
        t
      end        
    end
    
    def test_approx_duration_display
      puts approx_duration_display(30.seconds)
      puts approx_duration_display(25.5.minutes)
      puts approx_duration_display(1.5.hours)
      puts approx_duration_display(23.5.hours)
      puts approx_duration_display(3.5.days)
      puts approx_duration_display(2116800)
    end
  end
end
