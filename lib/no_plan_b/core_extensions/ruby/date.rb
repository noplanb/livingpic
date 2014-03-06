class Date
  def display_format
    if ( self == Date.today)
      "today"
    elsif ( self == Date.today + 1 )
      'tomorrow'
    elsif (self == Date.today - 1 )
      'yesterday'
    elsif ( (Date.today - self).to_i.between?(0,7))
      self.strftime('last %A')
    elsif ( (self - Date.today).to_i.between?(0,7) )
      self.strftime('next %A')      
    else
      self.strftime('%a, %b %d')
    end
  end
end
    