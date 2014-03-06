module NoPlanB
  module Helpers
    module DeviceAssetPathHelper
      
      extend self
      
      def device_image_path(path)
        if ENV["PRECOMPILE_TARGET"] == 'device'
          r = "img/#{path.gsub(/^\//, "")}"
        else
          r = "/assets/img/#{path.gsub(/^\//, "")}"
        end
        # puts "DEBUG: device_image_path = #{r}"
        r
      end
            
    end
  end
end