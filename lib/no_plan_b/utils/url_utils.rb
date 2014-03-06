module NoPlanB
  require File.dirname(__FILE__)+'/logging'
  module UrlUtils 

    require 'uri'
    require 'cgi'

    # Assumes simple-_scramble was available
    # require 'simple_scramble'

    extend self

    include NoPlanB::Logging
    
    

    def http_uri(url)
      return nil unless url
      url =~ /^https?:/i ? url : "http://" + url
    end

    # Get the domain name from the URL, for example, for www.woot.com it would be woot.com
    # This should be a bit faster (and less rigorous) than using URL to do the same thing
    def domain_name(url)
      return nil unless url
      if m=url.match(/([^.\/ ]+)\.(com|net|info|org|name|biz|gov|\w\w)(\.\w+)?(\/.*)*(\?.*)*$/)
        "#{m[1]}.#{m[2]}"
      else
        url
      end
    end
    
    # Get the domain name nickname, for example, for www.woot.com it would be woot
    def nickname(url)
      return nil unless url
      if m=url.match(/([^.\/ ]+)\.(com|net|info|org|name|biz|gov|\w\w)(\.\w+)?(\/.*)*(\?.*)*$/)
        m[1]
      else
        url
      end
    end

    # Returns true if the url is "local", meaning w/ an internal IP address or localhost or otherwise
    def local?(url,domain_name=nil)
      return nil unless url
      !!(url.match(%r{(^|://)(127|192|10)\.0}) || url.match(%r{(^|://)localhost}) || (domain_name && url.match(%r{\.#{domain_name}\b})))
    end
    
    def extend_url(url, params={})
      return nil unless url
      return url if params.empty?
      params.stringify_keys!
      url.strip!
      u = URI.parse(url)
      base =  u.scheme ? u.scheme + '://' + u.host : ''
      base += u.port ? ":#{u.port}" : ''
      base += u.path
      params=CGI.parse(u.query||'').merge(params)
      p = params.inject('') { |t,(k,v)| 
        v = [v] unless v.is_a?(Array)
        e = v.map{ |v1| "#{k}=#{CGI.escape(v1.to_s)}"}.join('&'); 
        t += t.empty? ? e : '&'+e 
      }
      url = base + '?' + p
    end

    # Slightly different form a normal path in that we use rails formatting in that if the last part of the 
    # path is a number we remove it
    def url_path(url)
      u = URI.parse(url)
      u.path.sub(%r{/\d+$},'')
    end
    
    # Take a parameter and encode and escape it for url embedding
    def scramble_encode(param)
      CGI.escape(SimpleScramble.scramble(param))
    end

    # Take a URL parameter that has been encoded and scramble it
    def scramble_unencode(param)
      param && SimpleScramble.unscramble(CGI.unescape(param))
    end

    # Take a parameter and encode and escape it for url embedding
    def encode_number(param)
      CGI.escape(SimpleScramble.scramble_number(param))
    end

    # Take a URL parameter that has been encoded and scramble it
    def unencode_number(param)
      param && SimpleScramble.unscramble_number(CGI.unescape(param))
    end

    # Take a URL parameter that has been encoded and already CGI unescaped and scramble it
    def scramble_unencode_unescaped(param)
      param && SimpleScramble.unscramble(param)
    end

    # Encode a reference to an object in a way that we can put it on the URL 
    def encode_object(object)
      scramble_encode("#{object.class}-#{object.id}")
    end

    # Assumes that we are using ActiveRecord objects because it tries to return the 
    # instantiated object
    def extract_encoded_object(param)
      return nil unless param
      s = SimpleScramble.unscramble(CGI.unescape(param))    
      (obj_class,obj_id) = s.split('-') unless ( s.blank? )
      obj_class && obj_id ? obj_class.constantize.find_by_id(obj_id) : nil
    end

    def query_params(url)
      uri = URI.parse(url)
      uri.query ? CGI.unescape(uri.query).split('&').map{ |m| m.split('=')}.inject({}) { |h,(p,v)| h[p] ? h[p].is_a?(Array) ? h[p] << v : h[p] = [h[p],v] : h[p] = v; h} : {}
    end

    SEARCH_ENGINES = %w{ www.google.com saerch.yahoo.com search.msn.com search.aol.com www.altavista.com www.feedster.com search.lycos.com www.alltheweb.com www.bing.com}

    SEARCH_REFERERS = {
          :google     => [/^http:\/\/(www\.)?google.*/, 'q'],
          :yahoo      => [/^http:\/\/search\.yahoo.*/, 'p'],
          :msn        => [/^http:\/\/search\.msn.*/, 'q'],
          :aol        => [/^http:\/\/search\.aol.*/, 'userQuery'],
          :altavista  => [/^http:\/\/(www\.)?altavista.*/, 'q'],
          :feedster   => [/^http:\/\/(www\.)?feedster.*/, 'q'],
          :lycos      => [/^http:\/\/search\.lycos.*/, 'query'],
          :alltheweb  => [/^http:\/\/(www\.)?alltheweb.*/, 'q'] 
        } unless defined?(SEARCH_REFERERS)

    SEARCH_STOP_WORDS = /\b(\d+|\w|about|after|also|an|and|are|as|at|be|because|before|between|but|by|can|com|de|do|en|for|from|has|how|however|htm|html|if|i|in|into|is|it|la|no|of|on|or|other|out|since|site|such|than|that|the|there|these|this|those|to|under|upon|vs|was|what|when|where|whether|which|who|will|with|within|without|www|you|your)\b/i unless defined?(SEARCH_STOP_WORDS)

    def hostname(url)
      return nil if url.nil? || url.strip.nil?
      url = url.strip
      url = "http://" + url unless url.match(/^http/i)
      # m = url.match(%r{(\w+)://([^/])+}) and m[1]
      begin 
        u = URI.parse(url) and u.host
      rescue StandardError => e
        logger.debug "Error parsing uri: '#{url}'"
        nil
      end
    end

    def is_search_engine?(url)
      SEARCH_ENGINES.include?(hostname(url).downcase)
    end

    def extract_search_terms(referer)

      # Get query args
      query_args =
        begin
          URI.split(referer)[7]
        rescue URI::InvalidURIError
          nil
        end

      # Determine the referring search that was used
      search_terms = nil
      raw_query = nil
      unless referer.blank?
        SEARCH_REFERERS.each do |k, v|
          reg, query_param_name = v
          # Check if the referrer is a search engine we are targetting
          if (reg.match(referer))

            # set the search engine
            engine = k 

            unless query_args.blank?
              query_args.split("&").each do |arg|
                pieces = arg.split('=')
                if pieces.length == 2 && pieces.first == query_param_name
                  unstopped_keywords = CGI.unescape(pieces.last)
                  raw_query = unstopped_keywords
                  search_terms = unstopped_keywords.gsub(SEARCH_STOP_WORDS, '').squeeze(' ')
                  #logger.info("Referring Search Keywords: #{search_terms}")
                  break
                end
              end
            end # unless
            break

          end # if
        end # do
      end #unless          

      return raw_query # because we found a match

    end

  end

  if __FILE__ == $0
    puts UrlUtils.local?("http://www.trymyui.com",'trymyui.com')
    
    puts UrlUtils.hostname("http://www.facebook.com/profile.php?id=1675380506")
    puts UrlUtils.hostname("http://apps.facebook.com/farmtown/play/?do=log&farm_uid=1314957324&action=memory&params=initial-61now-139&comments=")
    puts "Nick Names"
    puts UrlUtils.nickname("www.facebook.com/")
    puts UrlUtils.nickname("www.facebook.com?")
    puts UrlUtils.nickname("http://www.facebook.com/profile.php?id=1675380506")
    puts UrlUtils.nickname("http://www.facebook.com/profile.php?id=1675380506")
    puts UrlUtils.nickname("http://www.facebook.com?id=1675380506")
    puts UrlUtils.nickname("http://testlab.switch.ch/onlinetest/")
    puts "Domain Names"
    puts UrlUtils.domain_name("http://www.facebook.com?id=1675380506")
    puts UrlUtils.domain_name("http://testlab.switch.ch/onlinetest/")

  end
end
