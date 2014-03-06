module NoPlanB
  module Constants
    unless defined? URL_DETECTION
    
        # NOTE: tst is added for putting in an email address taht we don't want to go anywhere
      RE_DOMAIN_TLD   = '(?:[A-Za-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum|tst)'
      RE_DOMAIN_HEAD  = '(?:[A-Z0-9\-]+\.)+'  
      EMAIL_VALIDATION =   /(\A)([\w\.\-\+%]+)@(#{RE_DOMAIN_HEAD}#{RE_DOMAIN_TLD})(\z)/i
      EMAIL_DETECTION = /(\s|\A)([\w\.\-\+]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})(?=([.;,]?(\s|\z)))/i
      # $1 is the entire URL
      # $2 is the protocol:domain
      # $3 is the protocol
      # $4 is the domain suffix (e.g. .com, or .uk)
      # $5 ?
      # $6 is the port number
      # $7 is the path
      # $8 is an optional period or otherwise
      URL_DETECTION = %r{
        (?:\s|\A)
        # Match the leading part (proto://hostname, or just hostname)
        (
          # http://, or https:// leading part
          (https?)://(?:[-\w]+(\.\w[-\w]*)+|localhost)
        |
          # or, try to find a hostname with more specific sub-expression
          (?i: [a-z0-9] (?:[-a-z0-9]*[a-z0-9])? \. )+ # sub domains
          # Now ending .com, etc. For these, require lowercase
          (?-i: com\b
              | edu\b
              | biz\b
              | gov\b
              | in(?:t|fo)\b # .int or .info
              | mil\b
              | net\b
              | org\b
              | name\b
              | ([a-z][a-z]\.)?[a-z][a-z]\b # two-letter country code
          )
        )

        # Allow an optional port number - match 6
        ( : \d+ )?

        # The rest of the URL is the path, and begins with / and is unbroken - match 7
        (
          /\S*?
        )?
        # In case there is a valid sentence terminator, remove that - match 8
       (?=([.;,]?(?:\s|\z)))
      }ix

    end
  end
end
