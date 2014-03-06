class String


  # Try to intelligently truncate the string content  
  # Algorithm: we want this to be no more than limit characters as a simple truncation would do
  #   We never break in the middle of a word
  #   If the break_on_sentence option is specified, then if we see the end of the sentence w/ 25% of end, we use it 
  #   If the 
  # inputs
  #  limit: the number of characters we are interested in
  #  options: 
  #    :ellipsis  => Add ellipsis to the end of the string if there is more
  #    :break_on_sentence => Break on the last sentence if it is w/in 25% of the end of the content (default true)
  #    :sentence_break_limit  => Sets the percent value (default 25%) of length you're willing to give up to break on sentence
  #                             instead of on a word
  #    :strip_nl => Strip \n's 
  def briefly(limit,options={})
        
    brief = self.strip
    if ( options[:strip_nl] )
      brief.gsub!(/\n/,' ')
    end        
    
    return brief if brief.length <= limit

    # If we are to add ellipsis, then we need to reduce the character limit by 3
    limit -= 3 if options[:ellipsis]
    # Note that we're limiting to one extra character, i.e., limit and not limit-1
    brief = brief[0..limit]
    # We're at the end of a sentence, so just chop off the extra last character we had and return
    if ( brief[-2..-1] =~ /[.;\n]$/ ) 
      brief.chop!
    else 
      # backup to an end of word ... either the next letter is a non-word breaker, or else 
      # we're in the middle of a word and we back up  
      brief =  ( brief[-1..-1] =~ /[\s:,]/ ) ? brief.chop : brief[/(.*?)\s*[^\s:;.,]*\z/m,1 ]
      if ( options[:break_on_sentence]  )
        # if we have a full sentence, return it.  We consider it a full sentence if the last
        # letter is  

        last_sentence_end = brief =~ /[^;\n.]*\z/m
        if ( options[:sentence_break_limit].nil? )        
          sbl = 0.25
        else
          sbl = options[:sentence_break_limit] >= 100 ? 1.0 : \
          options[:sentence_break_limit] < 0 ? 0.0 : \
          options[:sentence_break_limit]/100.0
        end
        sbl = 1.0-sbl
        # puts  "last sentence end = #{last_sentence_end}, sentence limit = #{limit*sbl}"
        brief = brief[0..last_sentence_end-1].strip if (last_sentence_end >= limit*sbl )
      end
    end
    options[:ellipsis] ? brief+'&hellip;' : brief
  end 
  
  # Wrap the text to the indicated number of columns
  # Makes sure that words are not wrapped in the middle
  # NOTE: Currently does not hyphenate
  # If a sentence is greater than the indicated number of columns w/o having any breaks
  # then we present it as is
  # We prefer to break on spaces, but if there are none, then we look for punctuation marks
  BREAK_CHARS_RE = /[\s.,;:!?(-]/
  def wrap(columns=80)
    wrapped = []
    split("\n").each { |line| 
      while line.length > columns
        if m = line.rindex(BREAK_CHARS_RE,columns) || line.index(BREAK_CHARS_RE)
          wrapped << line.slice!(0,m + (line[m].chr == '(' ? 0 : 1) )
          line.lstrip!
        else
          # OK - go forward now until you find a break character
          break
        end
      end
      wrapped << line
    }
    wrapped.join("\n")
  end
  
  def capitalize_words
    r = self.downcase
    r.gsub!(/^[a-z]|\s+[a-z]/) { |a| a.upcase }
    r  
  end

  def capitalize_first
    r = self
    r.gsub(/^[a-z]/, r.first.upcase) 
  end
  
  def enclose(char)
    case char
    when '(' then "(#{self})"
    when '[' then "[#{self}]"
    when '{' then "{#{self}}"
    when "'" then "'#{self}'"
    when '"' then %{"#{self}"}
    else "#{char}#{self}#{char}"
    end
  end
  
  # This method considers whether a string is similar to another one
  # NOTE: it uses some rails methods - it's not pure ruby
  # It provides a similarity score (normalized to 1) that compares the number of shared words
  # to the average word length.
  # word 1    word 2    similar words   score
  #   1        1            1              1
  #   1        1            0              0
  #   2        1            1              .66
  #   3        1            1              .50
  #   3        2            1              .40
  #   4        1            1              .20
  #   4        2            2              .66
  #   4        2            1              .33
  #   4        3            1              .29
  #   4        3            2              .57
  #   4        3            3              .86
  # There should be a difference between having the items be in sequence
  # versus not be in sequence, but I'm not considering that now        
  # OPTIONS
  #   :ignore_words: array of words to ignore
  #   :min_word_length: the minimum word length to consider 
  def similarity_to(other,options={})
    shared_words = shared_words_with(other,options)
    shared_words.length * 2.0 / (words.length + other.words.length)
  end

  def words
    re = /[\s.,;:]+/
    self.split(re)
  end
  
  def shared_words_with(other,options={})
    ignore_words = options[:ignore_words] || []
    my_words = words.map { |w| w.singularize } - ignore_words
    other_words = (other.is_a?(Array) ? other : other.words).map { |w| w.singularize }  - ignore_words
    if ( options[:min_word_length] )
      my_words = my_words.select { |w| w.length >= options[:min_word_length] }
      other_words = other_words.select { |w| w.length >= options[:min_word_length] }
    end
    shared_words = my_words & other_words    
  end
  
  def most_similar(others,options={})
    i=most_similar_index(others,options)  and others[i]
    # most_similar = others.inject([]) { |r,o| r << [o,similarity_to(o,options)]}.sort_by{ |x| x[1] }.last
    # options[:threshold] ? most_similar[1] >= options[:threshold] ? most_similar[0] : nil : most_similar[0]
  end

  def most_similar_index(others,options={})
    most_similar = []
    others.each_with_index { |o,i| most_similar << [i,similarity_to(o,options)]}
    most_similar = most_similar.sort_by{ |x| x[1] }.last
    options[:threshold] ? most_similar[1] >= options[:threshold] ? most_similar[0] : nil : most_similar[0]
  end


  # Move the block of text some number of spaces left, 
  # options:
  #  :count => how many characters to move left by, if possible (default until one line is completely left-justified)
  #  :tab => how to interpret a tab character (default 2 spaces)  
  #  :sep => the separator acting as newline/carriage return - default = "\n"
  # NOTE: As a side-effect, all tabs are replaced by spaces
  #       
  def shift_left!(options={})
    max = 10000
    sep = options[:sep] || "\n"
    (lines = split(sep)).each { |line| 
      if m = line.match(/^\s+/)
        spaces = m[0].gsub('\t',' '*(options[:tab] || 2))
        line.gsub!(/^\s+/,spaces)
        max = [max,spaces.length].min
      else
        max = 0
        break
      end
    }
    if max > 0
      shift_left = options[:count] ? [options[:count],max].min : max
      self.replace(lines.map { |line| line[shift_left..-1] }.join(sep))
    end
    max > 0 ? max : nil
  end
  
  def shift_left(options={})
    c = dup
    c.shift_left!(options)
    c
  end
  
  # Shift the lines in the string to the right by some number of spaces - done inplace
  #  :count => spaces to move the item right by (default 2)
  def shift_right!(count=2)
    self.gsub!(/^./m,' '*count + '\0')
  end
  
  # Shift the lines in the string to the right by some number of spaces  and return the result
  # not affecting the original
  #  :count => spaces to move the item right by (default 2)
  def shift_right(count=2)
    c = dup
    c.shift_right!(count)
    c
  end
  
  def prepend_lines_with(s)
    gsub(/^/,s+'\1')
  end
  
  def self.random(length)
    valid_chars = ('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a
    a = []
    length.times { a << valid_chars[rand(valid_chars.length)] } 
    a.join
  end
  
  # ============================================================================
  # GARF WARNING TODO
  # = These should be moved elsewhere since they are not core string functions =
  # ============================================================================
  
  
  # do a simple text conversion to HTML
  #  * remove all the heading and training blank characters 
  #  * escape the HTML
  #  * convert double newlines to paragraphs
  #  * convert single newlines into <br/>
  #  * convert spaces into &nbsp;
  def as_html_deprecated #use TextEncoder.convert_to_html instead.
    return self if self.blank?
    mytext = self
    #mytext = CGI.escapeHTML(mytext)
    mytext.gsub!(NpbConstants::URL_DETECTION){|web_link| %{ <a href="#{web_link.strip}">#{web_link.strip}</a> }}
    #mytext.gsub!(NpbConstants::EMAIL_DETECTION){|email| %{\1<a href="mailto:#{email.strip}">#{email.strip}</a>}}
    mytext.gsub!(NpbConstants::EMAIL_DETECTION){|email| %{#{$1}<a href="mailto:#{email.strip}">#{email.strip}</a>}}
    mytext.gsub!(/\A +/) {|l_spaces| ("&nbsp;"*l_spaces.size)}    
    mytext.gsub!(/\n +/) {|l_spaces| ("\n" + ("&nbsp;"*(l_spaces.size-1)))}
    mytext.gsub!(/\n{2,}/,'</p><p>')
    mytext.gsub!(/(\n)([^\n])/, '<br/>\2')
    mytext
  end

  # Reverse the effects of a as_html operation as best you can, 
  # by unescaping escaped HTML and restoring paragraphs using double newlines.  
  # Note that the result is "approximately" the same as the original.  Leading and trailing
  # spaces may not be the same
  def as_text
    return self if self.blank?
    mytext = self.gsub(/<p>(.*?)<\/p>/mi,'\1'+"\n\n")
    mytext = mytext.gsub(/<br(.*?)>/mi,"\n") 
    mytext = mytext.gsub(/<p(.*?)>/mi,"\n\n") 
    mytext = mytext.gsub(/<\/p>/mi,"") 
    mytext = mytext.gsub(/<div(.*?)>/mi, "")
    mytext = mytext.gsub(/<\/div>/mi,"") 
    # Go ahead and strip all the other html tags as well
    mytext = mytext.gsub(/<\/?[^>]*>/, "")
    CGI.unescapeHTML(mytext).strip
  end
  
  # Strips out leading whitespace in html. 
  # In any html leader (html tags before the first text) it does the following:
  # 1) Change <p> to <span> and </p> to </span> 
  # 2) Remove any <br> or <br/>
  # 3) If the leader contains a <p> that is not closed then it looks for the closing </p>
  # in the portion following the leader and changes that to a </span>
  
  def lstrip_html
    return if self.blank?

    m = self.match(/\A(\s*?[^<]|(.*?)>\s*[^<])/) #Find first printing character
    return self unless m
    
    ldr = m[0]
    ldr_last = ldr.slice(ldr.size-1, ldr.size)
    ldr = ldr.slice(0,ldr.size-1) # portion up to the first printing character
    bdy =  ldr_last + m.post_match # portion following the first printing character
    
    cln_ldr = ldr.gsub(/<p/mi, "<span")
    cln_ldr = cln_ldr.gsub(/<\/p/mi, "</span")
    cln_ldr = cln_ldr.gsub(/<br(.*?)>/mi, "")
    
    m = bdy.match(/(\A.*?)<p/mi)
    if !m
      bdy = bdy.sub(/<\/p/mi, "</span") # change first closing </p> from an open <p> remaining from ldr
    else
      l = m.post_match
      f_cln = m[0].gsub(/<\/p/mi, "</span") # change any closing </p> from and open <p> remaining from ldr
      bdy = f_cln + l    
    end
    return cln_ldr + bdy   
  end
  
  # Strips all html from a string except for the tags identified by allow
  # allow is an array of tag names e.g.
  # allow = ['a','img','p','br','i','b','u','ul','li']
  def strip_html(allow)
    str = self.strip || ''
    allow_arr = allow.join('|')
    str = str.gsub(/<\s*/,'<')
    str = str.gsub(/<\/\s*/,'</')
    # First part of | prevents matches of </allowed. Second case prevents matches of <allowed
    # and keeps the / chacter from matching the ?! allowed.
    str.gsub(/<(\/(?!(#{allow_arr}))|(?!(\/|#{allow_arr})))[^>]*?>/mi,'')
  end
  
  private
  
end
