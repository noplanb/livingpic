module Combinations

  # Based on the notion that:
  # The ways to choose k elements out of a set of (n+1) elements are:
  # all of the ways to choose k elements from a set of n elements, plus
  # all the ways to add the new element to the choices of k-1 old elements

  extend self

  def binomials(n)
    (1..n).inject([]) { |r,i| r += (1..i).inject([]) { |m,j| m += choose(i,j) }}.uniq
  end
  
  def choose(n, k)
    return [[]] if n == 0 && k == 0
    return [] if n == 0 && k > 0
    return [[]] if n > 0 && k == 0
    new_element = n-1
    choose(n-1, k) + append_all(choose(n-1, k-1), new_element)
  end

  def append_all(lists, element)
    lists.map { |l| l << element }
  end

  # Return sorted subsets for length n
  # e.g. sorted_subsets(4) shoudl return [[[0,1,2,3]]; [[0,1,2]; [1,2,3]]; [[0,1]; [1,2]; [2,3]]; [[0],[1],[2],[3]]
  def sorted_subsets(length)
    combinations = []
    if ( length && length > 0 )
      base = (0...length).to_a
      # combinations[length] = base
      for i in 0...length
        j = length-i
        combinations[j-1] = []
        for k in 0..i
          combinations[j-1] << base[k...(k+j)]
        end
      end
    end
    combinations.reverse
  end
  
end

if __FILE__ == $0
  
  require 'test/unit'
  class TestCombinations < Test::Unit::TestCase
    # ==============
    # = Some tests =
    # ==============
    def test_base
      assert_equal [[]], Combinations.choose(3, 0)
      assert_equal [], Combinations.choose(0, 3)
    end

    def test_step
      # choose(1,1) == choose(0, 1) + append_all(choose(0, 0), 0)
      # == [] + append_all([[]], 0)
      # == [[0]]
      assert_equal [[0]], Combinations.choose(1, 1)
      assert_equal [[0,1], [0,2], [1,2]], Combinations.choose(3, 2)
      assert_equal [[0,1], [0,2], [1,2], [0,3], [1,3], [2,3]], Combinations.choose(4, 2)
      assert_equal [[0,1,2,3]], Combinations.choose(4, 4)
    end 
  
  end
end