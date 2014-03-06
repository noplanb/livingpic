# A module containing methods that allow various math functions to be performed on arrays
module NoPlanB
  module ArrayMathUtils

    extend self

    # Divide each element of the array by the divisor
    # If the divisor is a scalar, each element is divided by that value
    # If it's an array, then we do an element by element division
    # It's up to the caller to make sure this condition does not occur
    def ediv(arr,divisor)
      if divisor.is_a?(Array)
        raise "In array division, the two arguments must have the same length!" unless arr.length == divisor.length
        r = []
        (0...arr.length).each { |i| r[i] = arr[i]/divisor[i] }
        r
      else
        arr.map { |x| x/divisor }
      end
    end

    def emul(arr,multiplier)
      if multiplier.is_a?(Array)
        raise "In array multiplication, the two arguments must have the same length!" unless arr.length == multiplier.length
        r = []
        (0...arr.length).each { |i| r[i] = arr[i]*multiplier[i] }
        r
      else
        arr.map { |x| x*multiplier }
      end    
    end

    def eadd(arr,b)
      if b.is_a?(Array)
        raise "In array addition, the two arguments must have the same length!" unless arr.length == b.length
        r = []
        (0...arr.length).each { |i| r[i] = arr[i] + b[i] }
        r
      else
        arr.map { |x| x + b }
      end    
    end

    def esub(arr,b)
      if b.is_a?(Array)
        raise "In array subtraction, the two arguments must have the same length!" unless arr.length == b.length
        r = []
        (0...arr.length).each { |i| r[i] = arr[i] - b[i] }
        r
      else
        arr.map { |x| x - b }
      end    
    end

    # Given an array, integrate it sequentially and place the cumulation in the spot of each index
    # example:
    # integrate([1,2,3]) should be [1,3,6]
    # NOTE: only works for 1-dimensional arrays, and the values
    # must be numeric
    def integrate(arr,normalize_val=nil)
      r = arr.inject([0]) { |sum,x| sum << sum.last + x }[1..-1]
      normalize_val ? emul(r,normalize_val.to_f/r.last) : r
    end

  end
  
  if __FILE__ == $0
    require 'test/unit'
    class TestArrayMath < Test::Unit::TestCase

      include ArrayMathUtils
      def test_integrate
        assert_equal(6,ArrayMathUtils.integrate([1,2,3]).last)
      end
    end
  end
end

