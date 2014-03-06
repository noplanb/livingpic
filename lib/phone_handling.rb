# some methods for handling phone numbers
module PhoneHandling
  
  require 'yaml'
  
  extend self
  ISO = 0
  CODE = 1
  COUNTRY = 2
  SHORT_LIST = 3
  PHONE_HANDLING_CONFIG ||= YAML.load_file(File.join(Rails.root,"config","phone_handling_config.yml")).symbolize_keys
  ISO_CODE_COUNTRY ||= PHONE_HANDLING_CONFIG[:iso_code_country].select{|icc| icc[SHORT_LIST]}.map{ |icc| {:iso => icc[ISO], :code => icc[CODE], :country => icc[COUNTRY]} }
 
  def get_country_code_lookup(iso_code_country)
    result = {}
    iso_code_country.each do |icc|
      result[icc[:code]] = icc[:country]
    end
    result
  end
  
  COUNTRY_CODES ||= get_country_code_lookup(ISO_CODE_COUNTRY)
  # COUNTRY_CODES = {"93"=>"Afghanistan", "355"=>"Albania", "213"=>"Algeria", "1684"=>"American Samoa", "376"=>"Andorra", "244"=>"Angola", "1264"=>"Anguilla", "672\t0"=>"Antarctica", "1268"=>"Antigua and Barbuda", "54"=>"Argentina", "374"=>"Armenia", "297"=>"Aruba", "61"=>"Christmas Island", "43"=>"Austria", "994"=>"Azerbaijan", "1242"=>"Bahamas", "973"=>"Bahrain", "880"=>"Bangladesh", "1246"=>"Barbados", "375"=>"Belarus", "32"=>"Belgium", "501"=>"Belize", "229"=>"Benin", "1441"=>"Bermuda", "975"=>"Bhutan", "591"=>"Bolivia", "387"=>"Bosnia and Herzegovina", "267"=>"Botswana", "55"=>"Brazil", "0"=>"British Indian Ocean Territory", "1284"=>"British Virgin Islands", "673"=>"Brunei", "359"=>"Bulgaria", "226"=>"Burkina Faso", "95"=>"Burma (Myanmar)", "257"=>"Burundi", "855"=>"Cambodia", "237"=>"Cameroon", "1"=>"United States", "238"=>"Cape Verde", "1345"=>"Cayman Islands", "236"=>"Central African Republic", "235"=>"Chad", "56"=>"Chile", "86"=>"China", "61\t596"=>"Cocos (Keeling) Islands", "57"=>"Colombia", "269"=>"Comoros", "682"=>"Cook Islands", "506"=>"Costa Rica", "385"=>"Croatia", "53"=>"Cuba", "357"=>"Cyprus", "420"=>"Czech Republic", "243"=>"Democratic Republic of the Congo", "45"=>"Denmark", "253"=>"Djibouti", "1767"=>"Dominica", "1809"=>"Dominican Republic", "593"=>"Ecuador", "20"=>"Egypt", "503"=>"El Salvador", "240"=>"Equatorial Guinea", "291"=>"Eritrea", "372"=>"Estonia", "251"=>"Ethiopia", "500"=>"Falkland Islands", "298"=>"Faroe Islands", "679"=>"Fiji", "358"=>"Finland", "33"=>"France", "689"=>"French Polynesia", "241"=>"Gabon", "220"=>"Gambia", "995"=>"Georgia", "49"=>"Germany", "233"=>"Ghana", "350"=>"Gibraltar", "30"=>"Greece", "299"=>"Greenland", "1473"=>"Grenada", "1671"=>"Guam", "502"=>"Guatemala", "224"=>"Guinea", "245"=>"Guinea-Bissau", "592"=>"Guyana", "509"=>"Haiti", "39\t826"=>"Holy See (Vatican City)", "504"=>"Honduras", "852"=>"Hong Kong", "36"=>"Hungary", "354"=>"Iceland", "91"=>"India", "62"=>"Indonesia", "98"=>"Iran", "964"=>"Iraq", "353"=>"Ireland", "44"=>"United Kingdom", "972"=>"Israel", "39"=>"Italy", "225"=>"Ivory Coast", "1876"=>"Jamaica", "81"=>"Japan", "\t"=>"Western Sahara", "962"=>"Jordan", "7"=>"Russia", "254"=>"Kenya", "686"=>"Kiribati", "965"=>"Kuwait", "996"=>"Kyrgyzstan", "856"=>"Laos", "371"=>"Latvia", "961"=>"Lebanon", "266"=>"Lesotho", "231"=>"Liberia", "218"=>"Libya", "423"=>"Liechtenstein", "370"=>"Lithuania", "352"=>"Luxembourg", "853"=>"Macau", "389"=>"Macedonia", "261"=>"Madagascar", "265"=>"Malawi", "60"=>"Malaysia", "960"=>"Maldives", "223"=>"Mali", "356"=>"Malta", "692"=>"Marshall Islands", "222"=>"Mauritania", "230"=>"Mauritius", "262"=>"Mayotte", "52"=>"Mexico", "691"=>"Micronesia", "373"=>"Moldova", "377"=>"Monaco", "976"=>"Mongolia", "382"=>"Montenegro", "1664"=>"Montserrat", "212"=>"Morocco", "258"=>"Mozambique", "264"=>"Namibia", "674"=>"Nauru", "977"=>"Nepal", "31"=>"Netherlands", "599"=>"Netherlands Antilles", "687"=>"New Caledonia", "64"=>"New Zealand", "505"=>"Nicaragua", "227"=>"Niger", "234"=>"Nigeria", "683"=>"Niue", "850"=>"North Korea", "1670"=>"Northern Mariana Islands", "47"=>"Norway", "968"=>"Oman", "92"=>"Pakistan", "680"=>"Palau", "507"=>"Panama", "675"=>"Papua New Guinea", "595"=>"Paraguay", "51"=>"Peru", "63"=>"Philippines", "870\t48"=>"Pitcairn Islands", "48"=>"Poland", "351"=>"Portugal", "974"=>"Qatar", "242"=>"Republic of the Congo", "40"=>"Romania", "250"=>"Rwanda", "590"=>"Saint Barthelemy", "290"=>"Saint Helena", "1869"=>"Saint Kitts and Nevis", "1758"=>"Saint Lucia", "1599"=>"Saint Martin", "508"=>"Saint Pierre and Miquelon", "1784"=>"Saint Vincent and the Grenadines", "685"=>"Samoa", "378"=>"San Marino", "239"=>"Sao Tome and Principe", "966"=>"Saudi Arabia", "221"=>"Senegal", "381"=>"Serbia", "248"=>"Seychelles", "232"=>"Sierra Leone", "65"=>"Singapore", "421"=>"Slovakia", "386"=>"Slovenia", "677"=>"Solomon Islands", "252"=>"Somalia", "27"=>"South Africa", "82"=>"South Korea", "34"=>"Spain", "94"=>"Sri Lanka", "249"=>"Sudan", "597"=>"Suriname", "268"=>"Swaziland", "46"=>"Sweden", "41"=>"Switzerland", "963"=>"Syria", "886"=>"Taiwan", "992"=>"Tajikistan", "255"=>"Tanzania", "66"=>"Thailand", "670"=>"Timor-Leste", "228"=>"Togo", "690"=>"Tokelau", "676"=>"Tonga", "1868"=>"Trinidad and Tobago", "216"=>"Tunisia", "90"=>"Turkey", "993"=>"Turkmenistan", "1649"=>"Turks and Caicos Islands", "688"=>"Tuvalu", "256"=>"Uganda", "380"=>"Ukraine", "971"=>"United Arab Emirates", "598"=>"Uruguay", "1340"=>"US Virgin Islands", "998"=>"Uzbekistan", "678"=>"Vanuatu", "58"=>"Venezuela", "84"=>"Vietnam", "681"=>"Wallis and Futuna", "967"=>"Yemen", "260"=>"Zambia", "263"=>"Zimbabwe"} unless defined?(COUNTRY_CODES)
  
  
  @@_default_country_code = "1"
  def self.set_default_country_code(code)
    @@_default_country_code = code
  end
  
  def self.default_country_code
    @@_default_country_code
  end

  def  country_from_code(code)
    COUNTRY_CODES[code.to_s]
  end

  
  # strip the country code from the phone number
  # Look for two things: 011 (for the US), or preferably the + sign
  # Note that there are a few countries like Barbados and Dominican Republic that are modeled like US states
  # Also, it's hard to tell the difference between Canada & US, and we actually don't care much
  # returns an array with index 0 being the code and index 1 the number
  # TODO - make this work even if the + sign isn't included based upon the phone number length... 
  # e.g.
  #   code, num = country_code("+44889988998899") 
  #   puts code   => "44"
  #   puts num    => "889988998899"
  def strip_country_code(number)
    return nil unless number

    number = normalize_phone_number(number)
    if number.start_with?("+")
      number =  number[1..-1] 

      # Put in a hack for numbers like 15102223333
      if number.length == 11 && number.start_with?(@@_default_country_code)
        return [@@_default_country_code,number[1..-1]]
      end

      # Now go through the countries until we match
      (1..5).each do |i|
        if COUNTRY_CODES[number[0...i]]
          return [number[0...i], number[i..-1]]
        end
      end
    else 
      return [@@_default_country_code, number]
    end
  end
  
  # NOTE: doesn't differentiate between Canada, US islands, Guam,  Carribean Islands
  def is_international?(phone)
    country_code,number = strip_country_code(phone)
    country_code != @@_default_country_code
  end

  # normalize the phone number to strip all spaces, dashes, etc.
  # replace 011 with +
  # returns a phone number in international dialing format
  def normalize_phone_number(phone,country_code=1)
    if phone
      phone = phone.to_s.sub(/^011/,"+")
      "+" + (phone.start_with?("+") ? '' : country_code.to_s) + phone.gsub(/\D/,'') 
    end
  end

  # Given a US or canada number which may or may not have the country code in front
  def get_area_code(phone)
    country_code,number = strip_country_code(phone)
    if country_code == @@_default_country_code && number.length == 10
      number[0..2]
    else
      nil
    end
  end

  # Adds the area code to the number.  
  # GARF - this only works for US numbers right now and doesn't check
  def add_area_code(area_code,number)
    area_code.to_s + number.to_s
  end  

  # Format the phone.  Models include
  #  :parens: e.g. (415) 123 4567 or +1
  #  :dashed: e.g. 415-123-4567
  #  :spaces: e.g. 415 602 0256
  #  default => strips all non-numeric values
  # GARF - only works for US
  def format(number, options={})
    return nil unless number

    # options[:format] ||= :parens
    code,num = strip_country_code(normalize_phone_number(number))
    code ||= "1" if options[:country_code]
    case options[:format]
    when :parens
      (options[:country_code] ? "+#{code} " : '' ) + "(#{num[0..2]}) #{num[3..5]} #{num[6..9]}"
    when :dashes
      (options[:country_code] ? "+#{code}-" : '' ) + "#{num[0..2]}-#{num[3..5]}-#{num[6..9]}"
    when :spaces
      (options[:country_code] ? "+#{code} " : '' ) + "#{num[0..2]} #{num[3..5]} #{num[6..9]}"
    else
      (options[:country_code] ? "+#{code}" : '' ) + num
    end
  end
  
end

if $0 == __FILE__
  
  require 'test/unit'
  
  class TestIt < Test::Unit::TestCase
    include PhoneHandling
    
    def test_extract_country_code
      assert_nil(nil,strip_country_code(nil))
      assert_equal("44", strip_country_code("+448989898989")[0])
      assert_equal("98", strip_country_code("+98 711 345 5555")[0])
      assert_equal(@@_default_country_code, strip_country_code("711 345 5555")[0])
    end
    
    def test_normalize_phone_number
      assert_nil(nil,normalize_phone_number(nil))
      assert_equal("+11112223333", normalize_phone_number("(111) 222 3333"))
      assert_equal("+11112223333", normalize_phone_number("(111) 222-3333"))
      assert_equal("+11112223333", normalize_phone_number("111-222-3333"))
      assert_equal("+441112223333", normalize_phone_number("+44 111-222-3333"))
      assert_equal("+441112223333", normalize_phone_number("011 44 111-222-3333"))
    end
    
    def test_format
      assert_equal(nil, format(nil))
      assert_equal("111-222-3333", format("(111) 222 3333",{:format => :dashes}))
      assert_equal("111 222 3333", format("(111) 222 3333",{:format => :spaces}))
      assert_equal("(111) 222 3333", format("111-222-3333",{:format => :parens}))
      assert_equal("+1 (111) 222 3333", format("111-222-3333",{:format => :parens, :country_code => true}))
      assert_equal("+1-111-222-3333", format("111-222-3333",{:format => :dashes, :country_code => true}))      
      assert_equal("+1-111-222-3333", format("111-222-3333",{:format => :dashes, :country_code => true}))      
      assert_equal("+11112223333", format("111-222-3333",{:country_code => true}))
    end
    
  end
end
