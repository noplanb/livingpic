require 'test_helper'
require 'sms_template'

class SmsTemplateTest < ActiveSupport::TestCase

  SmsTemplate.config_file = File.join(File.dirname(__FILE__),'sms_templates.yml')
  SmsTemplate.load_config_file
  
  test "all templates read" do 
    assert_equal 9, SmsTemplate.count
    assert_equal 2, SmsTemplate.count(:blue)
    assert_equal 5, SmsTemplate.count(:purple)
  end
  
  test "latest versions read correctly" do
    assert_equal 2, SmsTemplate[:blue].version
    assert_equal 5, SmsTemplate[:purple].version
    assert_equal 2, SmsTemplate[:green].version
    assert SmsTemplate[:blue].template.match( /version 2/), "Blue template version not correct?"
    assert SmsTemplate[:purple].template.match( /version 5/), "Purple template version not correct?"
    assert SmsTemplate[:blue].template.match( /blue/), "Blue template not correct?"
    assert SmsTemplate[:purple].template.match( /purple/), "Purple template not correct?"
  end

  test "individual version read correctly" do 
    assert_equal 1, SmsTemplate[:blue,1].version
    assert_equal 3, SmsTemplate[:purple,3].version
  end

  test "bogus version raises error" do
    assert_raise(Exception) { SmsTemplate[:blue,10] }
  end
  
  test "variables filled in correctly" do
    user = OpenStruct.new(:name => "joseph", :email => "x@y.com")
    assert_match /joseph/, SmsTemplate[:blue].fill(:user => user)
    assert_match /x@y\.com/, SmsTemplate[:blue,1].fill(:user => user)
  end
  
end
