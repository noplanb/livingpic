require 'rational'
# Implement some rational math for handling various strings
module NoPlanB
  module NumberUtils
    extend self
    
    # Adds the commas to an int
    def commify(v, delimiter=",")
     (s=v.to_s;x=s.length;s).rjust(x+(3-(x%3))).scan(/.{3}/).join(delimiter).strip
    end
    
    # Parses a string, returning a rational number
    # The string can be of the form 1 2/3, or 1-2/3
    def parse_fractional(num)
      return nil unless num
      num.strip!
      if m=num.match( %r{^(\d+\.\d+)})
        m[0].to_f
      end
    end

    def parse_rational(num)
      return nil unless num
      num.strip!
      nums = num.split(/[- ]/)
      val = if m= num.match( %r{^(\d+)[- ]+(\d+)\/(\d+)})
        m[1].to_i + Rational(m[2].to_i,m[3].to_i) 
      elsif m= num.match( %r{^(\d+)\/(\d+)} )
        Rational(m[1].to_i,m[2].to_i)
      elsif m = num.match( %r{^(\d+)})
        m[1].to_i
      end
      val
    end

    # Returns floating point number that is the result of parsing the string
    def parse(num)
      # parse_rational(num) || parse_fractional(num) 
      (parse_fractional(num) || parse_rational(num)).to_f
    end

  end
  if __FILE__ == $0
    puts NumberUtils.parse("1")
    puts NumberUtils.parse("1/2")
    puts NumberUtils.parse("13/2")
    puts NumberUtils.parse("1 3/2")
    puts NumberUtils.parse("1- 3/2")
    puts NumberUtils.parse("1 - 3/2")
    puts NumberUtils.parse("1-2/3")
    puts NumberUtils.parse("1-2/3 - 2")
    puts NumberUtils.parse("1.5")
    puts NumberUtils.parse("1")
  end
  
  
end
