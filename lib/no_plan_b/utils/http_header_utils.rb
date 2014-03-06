# Some utilities for parsing the browser information
module NoPlanB
  module HttpHeaderUtils

    extend self

    # Returns the browser string as browser/version
    def extract_browser_info(string)
      return nil if string.nil?

      if bot = bot_match(string) 
        bot 
        # Chrome has to come before safari else the browser is identified as Safari b/c chrome sends both chrome and safari
      elsif string.match(/chrome\/([\d.]+)/i)
        "Chrome/#{$1}"
      elsif string.match(/MSIE[\s\/]([\d.]*)/i)
        "MSIE" + ($1.blank? ? '' : "/#{$1}" )
      elsif string.match(/Version\/([\d.]*) Safari/i)
        "Safari" + ($1.blank? ? '' : "/#{$1}" )
      elsif string.match(/Safari[\s\/]*([\d.]*)/i)
        "Safari" + ($1.blank? ? '' : "/#{$1}" )
      elsif string.match(/FireFox\/([\d.]*)/i)
        "FireFox/#{$1}"
      elsif string.match(/AOL ([\d.]*)/)
        "AOL/#{$1}"
      elsif string.match(/Playstation ([\d.]*)/i)
        "Playstation/#{$1}"
      elsif string.match(/Netscape\/([\d.]*)/i)
        "Netscape/#{$1}"
      elsif string.match(/Mozilla\/([\d.]+)/)
        "Mozilla/#{$1}"
      elsif string.match(/Mozilla/)
        "Mozilla"
      elsif string.match(/Opera/)
        "Opera"
      elsif string.match(/(MIDP[-.a-zA-Z0-9]*)/i)
        $1
      else 
        nil
      end
    end

    # Returns the system as type/OS/version
    def extract_system_info(string)
      return nil if string.nil?

      if string.match(/Windows NT\s*([\d.]*)/)
        "Windows/#{$1}"
      elsif string.match(/OS X\s*([\d_.]*)/)
        "Mac" + ($1.blank? ? '' : "/#{$1.gsub('_','.')}")
      elsif string.match(/Mac[\s\/]*([\d_.]*)/)
        "Mac" + ($1.blank? ? '' : "/#{$1.gsub('_','.')}")
      elsif string.match(/iPhone/)
        "iPhone"
      elsif string.match(/Linux\s*([\d_]*)/)
        "Linux"
      elsif string.match(/Mac_PPC/i)
        "Mac(PPC)"
      elsif string.match(/SunOS/i)
        "Sun"
      elsif string.match(/Blackberry/i)
        "Blackberry"
      elsif string.match(/Win\s*9(\d+)/i)
        "Win 9#{$1}"
      elsif string.match(/Windows[\s\/]([\d.]*)/i)
        "Windows" + ($1.blank? ? '' : "/#{$1.gsub('_','.')}")
      elsif string.match(/Danger/i)
        "Danger"
      else 
        nil
      end
    end

    # WARNING: IF it's a bot, make sure that it's defined as \w+Bot so we can recognize 
    # it later
    def bot_match(string)
      return nil if string.nil?
      if string.match(/moozilla/i)
        "MoozillaBot"
      elsif string.match(/slurp/i)
        "YahooBot"
      elsif string.match(/googlebot/i)
        "GoogleBot"
      elsif string.match(/AdsBot-Google/i)
        "GoogleAdsBot"
      elsif string.match(/google keyword tool/i)
        "GoogleKeywordBot"
      elsif string.match(/msnbot/i)  
        "MsnBot"
      elsif string.match(/adbot/i)
        "GoogleAdBot"
      elsif string.match(/SPENG/)
        "SiteProbeBot"
      elsif string.match(/(facebookexternalhit|facebookbot)/i)
        "FacebookBot"
      elsif string.match(/SurveyBot/)
        "SurveyBot"
      elsif string.match(/Ask Jeeves/)
        "AskBot"
      elsif string.match(/DotBot/)
        "DotBot"
      elsif string.match(/([a-zA-Z\-\/]+Bot)/)
        $1
      elsif string.match(/Trend Micro/i)
        "TrendMicroBot"
      elsif string.match(/CyberPatrol/i)
        "CyberPatrolBot"
      elsif string.match(/ia_archiver/i)
        "AlexaBot"
      elsif string.match(/Ginxbot/i)
        "GinxBot"
      elsif string.match(/Chat Catcher/i)
        "ChatCatcherBot"
      elsif string.match(/AideRSS/i)
        "AideRSSBot"
      elsif string.match(/Baiduspider/i)
        "BaiduBot"
      elsif string.match(/ExaBot/i)
        "ExaBot"
      elsif string.match(/Twiceler/i)
        "CuilBot"
      elsif string.match(/ScoutJet/i)
        "ScoutJetBot"
      elsif string.match(/\b(.*)bot\b/i)
        "#{$1}Bot"
      elsif string.match(/\b(\w+)lib\b/i)
        "#{$1}Bot"
      elsif string.match(/\bJava\d+\b/i)
        "JavaBot"
      elsif string.match(/\bmonit/i)
        "MonitBot"
      end
    end
  end
end