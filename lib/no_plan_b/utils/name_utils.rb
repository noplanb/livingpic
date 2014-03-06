module NoPlanB
  module NameUtils
    # Normalize the name
    # Capitalize first, unless there it is is already mixed case
    # don't allow two caps next to each other, so can support names like McDuff
    def normalize_case(name)
      if name
        name.match(/[A-Z]/) && !name.match(/[A-Z]{2,}/) ? name : name.downcase.capitalize
      end
    end

    def name
      "#{first_name} #{last_name}"
    end
  end
end    

if $0 == __FILE__
  require 'test/unit'

  class TestNameUtils < Test::Unit::TestCase
    include NoPlanB::NameUtils

    def test_names
      assert_nil(normalize_case(nil))
      assert_equal("Jones", normalize_case('jones'))
      assert_equal("Jones", normalize_case('JONES'))
      assert_equal("Jones", normalize_case('Jones'))
      
      assert_equal("von Buren", normalize_case("von Buren"))
      assert_equal("McReady", normalize_case("McReady"))
      assert_equal("Mcready", normalize_case("mcready"))
      assert_equal("Mcready", normalize_case("mcREADY"))
    end
  end
end

    