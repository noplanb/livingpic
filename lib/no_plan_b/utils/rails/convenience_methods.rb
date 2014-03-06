# A small group of methods that would be convenient to have anywhere, not just in the view, but in
# other modules as well
module NoPlanB
  module Rails
    module ConvenienceMethods

      def current_url
        request.url
      end
  
      def current_protocol
        request.protocol
      end
  
      def local_host?
        ["localhost","127.0.0.1"].include? request.host 
      end
  
      # The name of the current host (localhost, for example)
      def current_host
        request.host
      end

      def current_port
        request.port
      end
  
      def current_action
        request.path_parameters[:action] && request.path_parameters[:action].downcase
      end
  
      def current_controller
        request.path_parameters[:controller] && request.path_parameters[:controller].downcase
      end
  
      def current_site_url
        "http://#{request.host_with_port}"
      end
  
      # Return the users's sytem information as a hash
      def user_system_info
        {
          :system => NoPlanB::HttpHeaderUtils.extract_system_info(request.env['HTTP_USER_AGENT']),
          :browser => NoPlanB::HttpHeaderUtils.extract_browser_info(request.env['HTTP_USER_AGENT']),
          :ip_address => request.remote_ip
        }
      end

      # Return the referer information - if it was via search, return the search terms used
      def referer_info
        { 
          :url => request.env["HTTP_REFERER"],
          :host => NoPlanB::UrlUtils.hostname(request.env["HTTP_REFERER"]),
          :search_engine => NoPlanB::UrlUtils.is_search_engine?(request.env["HTTP_REFERER"]),
          :search_terms => NoPlanB::UrlUtils.extract_search_terms(request.env["HTTP_REFERER"])
         }
      end
      
      def is_android?
        request.env['HTTP_USER_AGENT'][/\b(android)\b/i]
      end

      def is_iphone?
        request.env['HTTP_USER_AGENT'][/\b(ipod|iphone|ipad)\b/i]
      end
      
      def isMac?
        (system = NoPlanB::HttpHeaderUtils.extract_system_info(request.env['HTTP_USER_AGENT'])) and system.match(/mac/i);
      end
      alias_method :is_mac?, :isMac?
      
      def isMacLion?
        (system = NoPlanB::HttpHeaderUtils.extract_system_info(request.env['HTTP_USER_AGENT'])) and system.match(/mac/i) and system.match(/10[_.]7/i);
      end
      alias_method :is_mac_lion?, :isMacLion?
      
      def isWindows?
        (system = NoPlanB::HttpHeaderUtils.extract_system_info(request.env['HTTP_USER_AGENT'])) and system.match(/windows/i);
      end
      alias_method :is_windows?, :isWindows?
      
    end
  end
end
