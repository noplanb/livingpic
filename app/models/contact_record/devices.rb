module ContactRecordExtension
  module Devices

    unloadable

    # Format the contact records
    def format_from_device(params)
      # Normalized the browser to match cordova contact format for iphone and android
      # the iphoneand android params format is:
      # {"name":{"givenName":"Mitch","formatted":"Mitch DeShields","middleName":null,"familyName":"DeShields","honorificPrefix":null,"honorificSuffix":null},"id":258,"displayName":null,"phoneNumbers":[{"type":"work","value":"415-578-4482","id":0,"pref":false},{"type":"home","value":"415-453-2259","id":1,"pref":false},{"type":"mobile","value":"650-270-6969","id":3,"pref":false},{"type":"home","value":"(208) 450-5105","id":4,"pref":false}],"emails":[{"type":"other","value":"mdeshields@nexxofinancial.com","id":0,"pref":false}]}
      if params and params['name']
        {
         :first_name => params['name']['givenName'],
         :last_name => params['name']['familyName'],
         :contact_details_attributes => (params['phoneNumbers'] ? params['phoneNumbers'].map { |pr| {:field_name => pr['type'], :field_value => pr['value']} } : []) + 
            (params['emails'] ? params['emails'].map { |pr| {:field_name => pr['type'], :field_value => pr['value']} } : [])
        }
      end
    end

  end
end
