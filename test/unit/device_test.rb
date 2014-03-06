require 'test_helper'

class DeviceTest < ActiveSupport::TestCase

  setup do 
    @device = Device.create!(platform: "IOS", version: "1.0", user_id: 1)
  end

  test "should only log one device per user" do
    assert_raise(ActiveRecord::RecordInvalid) { 
      Device.create!(platform: "ios", version: "1.0", user_id: 1)
    }
    assert_raise(ActiveRecord::RecordInvalid) { 
      Device.create!(platform: "IOS", version: "1.0", user_id: 1)
    }
  end

  test "platform string should be downcased" do
    assert_equal("ios", @device.platform)
  end

  test "should allow multiple platforms and versions for one user" do
    assert_nothing_thrown { 
      Device.create!(platform: "IOS", version: "1.1", user_id: 1)
    }
    assert_equal(2, Device.where(:user_id => 1).count)
  end

  test "should allow platforms and versions for multiple users" do
    assert_nothing_thrown { 
      Device.create!(platform: "IOS", version: "1.1", user_id: 2)
    }
  end

  test "shouldn't log a device if required strings are not there" do
    assert_raise(ActiveRecord::RecordInvalid) { 
      Device.create!(platform: "", version: "1.0", user_id: 1)
    }    
    assert_raise(ActiveRecord::RecordInvalid) { 
      Device.create!(platform: "ios", version: "", user_id: 1)
    }
    assert_raise(ActiveRecord::RecordInvalid) { 
      Device.create!(platform: "ios", version: "", user_id: 1)
    }
  end
end
