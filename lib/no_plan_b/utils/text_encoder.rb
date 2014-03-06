module NoPlanB
  # This module is responsible for understanding encoding the text according to our model, which is similar but not exactly
  # the same as textilize.
  # It performs the following:
  #   - Single newlines are translated to <br/>
  #   - Double newlines are translated to <p/>
  #   - links and anything starting with wwww. is translated to <a > links
  #   - emails are translated to <mailto:> links
  #   - sequences of lines, in between '>--' delimiters, and starting with '> ' are translated into quotes
  #   - 
  # NOTE: I don't want there to be too many <br/>'s in there, so some of the encodings encode the line so that it's newline is not
  # converted to a <br/>.   You'll see references to "<nl>" in some of the code for this...
  # WARNING: The unconversions are not done correctly!

  require File.expand_path(File.join(File.dirname(__FILE__),"..","constants.rb"))

  module TextEncoder
    
    def self.show_regexp(a, re)
      if a =~ re
        "#{$`}<<#{$&}>>#{$'}"
      else
        "no match"
      end
    end
    
    def self.start_section_encoding
      %{<div class="section">}
    end
    
    def self.end_section_encoding
      "</div>"
    end
    
    # the regular expression we use to find a section heading
    def self.section_re
      /(^|\n)\s*\*\*(.*?)\*\*\s*?(\n|$)/
    end
    
    def self.numbered_line_re
      /^\s*#\s+/
    end
    

    # Take a chunk of text which includes the following markup language and execute the appropriate pdf commands:
    # **Section head** /n
    #  # Numbered item  /n
    #
    # Split lines of text into an array on /n's
    # Put the lines into an array of hashes (s).
    # Hash keys can be:
    # :type => :text, :start_num, :end_num, :num, :section
    # :number => '5' for example.
    # :text => 'the actual text associated with the line'
    def self.structure_markup_text(text)
      s = []
      lines = text.split("\n")
      i = 0
      n = 1
      r = 1
      lines.each do |l|
        if m = l.match(section_re)
          if n != 1
            s[i] = {:type => :end_num_block}
            i += 1
          end
          s[i] = {:type => :section, :text => m[2] + "\n"}
          n = 1
        elsif m = l.match(numbered_line_re)
          if n == 1
            s[i] = {:type => :start_num_block}
            i += 1
          end
          s[i] = {:type => :num, :number => n.to_s, :text => m.post_match + "\n"}
          n += 1
        else
          if n != 1 
            s[i] = {:type => :num, :number => nil, :text => l + "\n"}
          else
            s[i] = {:type => :text, :text => l + "\n"}
          end
        end
        i += 1
      end
      if n != 1
        s[i] = {:type => :end_num_block}
      end
      return s
    end
    
    # Split text up into sections, each of which has some a list of lines in it
    def self.split_into_sections(text)
      lines = text.split("\n")
      current_section = {:lines => [],:heading =>''}
      sections = [current_section]
      lines.each { |line|
        if line.match(section_re)
          current_section = {}
          current_section[:heading] = line
          current_section[:lines] = []
          sections << current_section
        else
          current_section[:lines] << line
        end
      }
      sections
    end
    
    def self.join_sections(sections)
      sections.map{ |s| (s[:heading].blank? ? '' : "#{s[:heading]}\n" ) + s[:lines].join("\n")}.join("\n")
    end
    

    # Extract the start and end line numbers of a block of lines that should be numbered and belong together
    # returns a two-element array with first and last indexes
    # Currently very simple
    def self.extract_number_blocks(lines)
      match_lines = []
      lines.each_with_index { |line,i| match_lines << i if line.match(/^\s*#\s+/) }
      match_lines.blank? ? [] : [match_lines.first, match_lines.last]
    end
    
    # These represent blocks of lines that should have their list items converted
    # The match_string is something like '^\s*#\s+' or '^\s*-\s+'
    # This is replaced in the format string
    def self.convert_list_item_block(lines,match_string,options={})
      format_string = options[:format_string] || '$TEXT'
      # puts "groups = #{groups.inspect}"
      format_string = format_string.gsub('$TEXT','\\\\'+'1')
      lines = lines.dup
      first,last = nil,nil
      affected_lines = lines.select { |line| line.match(/^#{match_string}/) }
      lines.each_with_index { |line,i|
        next unless line.match(/^#{match_string}/)
        first ||= i
        last = i
        if ( affected_lines.length > 1 )
          format_string.gsub('$NUM', (i+1).to_s ) 
          line.gsub!(/^#{match_string}(.*)/,format_string)
        else
          line.gsub!(/^#{match_string}/,'')
        end
      } 
      if ( affected_lines.length > 1 && first && last && options[:surround_with])
        lines = lines.insert(last+1, options[:surround_with][1])
        lines = lines.insert(first, options[:surround_with][0])
      end
      lines
    end
    
    # See if the site has numbers, and if so, convert them
    # You can pass in a string pattern that uses the number instead,
    # where the number to be replaced is represented as $NUM, and the text is $TEXT
    # For example, to put a class around it, use "span <class='number'> $NUM </span> $TEXT"
    def self.convert_numbers_generically(text,format_string="$NUM. $TEXT")
      lines = text.split("\n")
      match_lines,sections = [],[]
      lines.each_with_index { |line,i| match_lines << i if line.match(/^\s*#\s+/); sections << i if TextEncoder::section_re.match(line) }
      # puts "match_lines = #{match_lines.inspect}"
      # puts "sections = #{sections.inspect}"
      groups = []
      if ( sections.empty? )
        groups = [match_lines ]
      else
        groups[0]  = match_lines.select { |l| l < sections.first } 
        for i in 0...sections.length-1 do
          groups[i+1] = match_lines.select { |l| l >= sections[i] && l < sections[i+1] }
        end
        last_sec = sections.last || 0
        groups[sections.length] = match_lines.select { |l| l >= last_sec } 
      end
      # puts "groups = #{groups.inspect}"
      groups.reverse.each { |match_lines| 
        next  if ( match_lines.empty? || match_lines.length < 1 )
        # puts "format_string = #{format_string}"
        fs = format_string.gsub('$TEXT','\\\1')
        match_lines.each_with_index { |line,i|
          s = fs.gsub('$NUM',(i+1).to_s)
          # puts "s = #{s.inspect}"
          lines[line].gsub!(/^\s*#\s+(.*)/,s)
        } 
      }
      lines.join("\n")
    end
    
    def self.convert_bullets_generically(text,format_string="* $TEXT")
      (lines,groups,match_lines) = parse_for_items(text,/^\s*-\s+/)
      # puts "groups = #{groups.inspect}"
      groups.reverse.each { |match_lines| 
        # split the lines into sections
        next  if ( match_lines.blank? || match_lines < 1 )
        format_string = format_string.gsub('$TEXT','\1')
        match_lines.each_with_index { |line,i|
          lines[line].gsub!(/^\s*-\s+(.*)/,format_string + "\n<nl>")
        } 
      }
      lines.join("\n")
    end
    
    
    # Convert the section heading generically
    # You can pass in a formatting string.  $SEC in the formatting string will be replaced by the actual section text.
    def self.convert_section_generically(text,format_string="$SEC")
      (m=text.match(section_re)) ? convert_section_generically(m.pre_match + format_string.gsub('$SEC',m[2]) +m.post_match,format_string) : text
    end
    
    # Preparse the selection and return the two arrays:
    # groups returning the 
    # split lines
    # groups, where each group shows the beginning and end line
    # the lines that match the regexp, so you can figure out which groups the go into
    def self.parse_for_items(text,line_regexp)
      lines = text.split("\n")
      match_lines,sections = [],[]
      lines.each_with_index { |line,i| match_lines << i if line.match(line_regexp); sections << i if TextEncoder::section_re.match(line) }
      # puts "match_lines = #{match_lines.inspect}"
      # puts "sections = #{sections.inspect}"
      groups = []
      if ( sections.blank? )
        groups = [match_lines ]
      else
        groups[0]  = match_lines.select { |l| l < sections.first } 
        for i in 0...sections.length-1 do
          groups[i+1] = match_lines.select { |l| l >= sections[i] && l < sections[i+1] }
        end
        last_sec = sections.last || 0
        groups[sections.length] = match_lines.select { |l| l >= last_sec } 
      end
      [lines,groups,match_lines]
    end
    
    
    module ConvertToHtml

      unless defined?(R)
        # Don't do the parens-based naming... it's too confusing
        # parens = '(?:\s*'+Regexp.escape('(')+'(.*?)'+Regexp.escape(')')+')' 
        # R = Regexp.new(%{(#{NoPlanB::Constants::URL_DETECTION.source})#{parens}*},NoPlanB::Constants::URL_DETECTION.options)
        R = Regexp.new(%{(#{NoPlanB::Constants::URL_DETECTION.source})},NoPlanB::Constants::URL_DETECTION.options)
      end

      # This automatically converts open links found in the text to <a links>
      # In the case where the link is in something like the following format
      # link(link name), it will put the link name as the link for the text 
      def convert_links(text)
        text && text.gsub(R) { |x| %{#{leading_space($1)}<a title="Link" target="_blank" href="#{format_link($1).strip}">#{$1.strip}</a>}  }
        # text.gsub(NoPlanB::Constants::URL_DETECTION){|web_link| %{ <a href="#{web_link.strip}">#{web_link.strip}</a> }}
      end

      def leading_space(link)
        if m = link.match(/^\s+/) then return m[0]; end
      end
      
      def format_link(link)
        link = 'http://' + link.strip unless ( link =~ /^\s*http/i)
        link
      end
      
      def convert_leading_spaces(text)
        text.gsub(/\A\s+/, "")
      end
      
      def convert_line_breaks(text)
        text = text.gsub(/<nl>\n/, "<nl>") # replace all the intentional newlines to newlines
        text = text.gsub(/\n/, ' <br/> ') # The spaces around <br/> are necessary so that emails and links are properly recognized.
        text.gsub(/<nl>/, "\n") # replace all the intentional newlines to newlines
      end

      def convert_emails(text)
        #Added the $1 below to put the leading delimiter that got eaten back in the output.
        text.gsub(NoPlanB::Constants::EMAIL_DETECTION){|email| %{#{$1}<a title="Email" href="mailto:#{email.strip}">#{email.strip}</a>}}
      end

      def convert_multiple_spaces(text)
        text.gsub(/(^| ) +/) {|spaces| ("&nbsp;"*spaces.size)}
      end
      
      # A section is delimited by ** Text ** 
      # There shouldn't be anything else after the text
      def convert_sections(text)
        convert_section_generically(text,"<nl>#{TextEncoder::start_section_encoding}$SEC#{TextEncoder::end_section_encoding}<nl>")
      end
      
      def convert_bold(text)
        text.gsub(/(\s)\*(\S.*?\S[.;,\t '"\/_])\*/,'\1<b>\2</b>')
      end
      
      def convert_italic(text)
        text.gsub(/(\s)\/(\S.*?\S[.;,\t '"*_])\//,'\1<i>\2</i>')
      end
      
      def convert_underline(text)
        text.gsub(/(\s)_(\S.*?\S[.;,\t '"\/*])_/,'\1<u>\2</u>')
      end
      
      def convert_numbers(text)
        sections = split_into_sections(text)
        sections.each { |section| 
          section[:lines] = convert_list_item_block(section[:lines],'\s*#\s+',:format_string => '<li>$TEXT</li><nl>',:surround_with => ['<ol><nl>','</ol><nl>']) 
        }
        join_sections(sections)
      end
      
      def convert_numbers_span(text)
        sections = split_into_sections(text)
        sections.each { |section| 
          n = extract_number_blocks(section[:lines])
          lines = convert_list_item_block(section[:lines],'\s*#\s+',:format_string => '<span class="numbers">$NUM</span> $TEXT')
        }
        join_sections(sections)
        # convert_numbers_generically(text,'<span class="numbers">$NUM</span>')
      end
      
      def convert_bullets(text)
        sections = split_into_sections(text)
        sections.each { |section| 
          section[:lines] = convert_list_item_block(section[:lines],'\s*-\s+',:format_string => '<li>$TEXT</li><nl>',:surround_with => ['<ul><nl>','</ul><nl>']) 
        }
        join_sections(sections)      
      end
      
      def convert_quotes(text)
        #text.gsub(/>---(.*?)\n((> .*\n)+)>---(.*?)\n/) { |quote| unquote(quote) }
        text = text.gsub(/_"\s+/, '_" ') #Leave only 1 space after begin quote
        text = text.gsub(/\s+"_/, ' "_') #Leave only 1 space before end quote
        text = text.gsub(/_"/, %{<div class='inline-quote'><span class='q'>})
        text.gsub(/"_/, %{</span></div>})
      end

      # remove the quotes and convert them to html
      def unquote_deprecated(text)
        text = text.gsub(/>---(.*?)\n/m,'')
        text = text.gsub(/> /m,' ')
        text = text.gsub("\n",' ')
        return %{<div class='inline-quote'><span class='q'>#{text}</span></div> }
      end
      private :unquote_deprecated
      
     # Convert any special characters in the text
      def convert_special_chars(text)
        convert_bold(convert_italic(convert_underline(text)))
      end

      # Make the html safe by converting all < and > tags to appropriate html encoding
      def make_html_safe(text,allow=['a','img','p','br','i','b','u','ul','li'])
        str = text.strip || ''
        allow_arr = allow.join('|')
        str = str.gsub(/<\s*/,'<')
        str = str.gsub(/<\/\s*/,'</')
        # First part of | prevents matches of </allowed. Second case prevents matches of <allowed
        # and keeps the / chacter from matching the ?! allowed.
        str.gsub(/<(\/(?!(#{allow_arr}))|(?!(\/|#{allow_arr})))[^>]*?>/mi,'')
      end

      def convert_to_html(text)
        return text if text.blank?
        
        convert_line_breaks(
          convert_multiple_spaces( 
            convert_sections(
                convert_emails(
                  convert_links(
                    convert_quotes(
                      convert_numbers(
                        convert_bullets(
                          convert_leading_spaces(text)
        ) ) ) ) ) ) ) )
      end
       
    end

    # This module takes HTML created from our format and coverts it back to text (this is hard...) 
    # It's just a placeholder depending upon if I ever need it or not
    module ConvertFromHtml

      def unconvert_links_and_emails(text)
        # text.gsub(/<a.*href="(.*?)".*>(.*?)<\/a>/) { |link| $1 =~/mailto:/ ? link : %{#{$1} (#{$2})}}
        text.gsub(/<a.*?href="(.*?)".*?>(.*?)<\/a>/) { |link|
          l = $1
          n = $2 
          if l =~ /mailto:/
            l.gsub(/mailto:/, "")
          else
            %{#{l} (#{n})}
          end
        }
      end
      
      # "hello".gsub(/(hel)(lo)/) {%{#{$2} #{$1}}}
      
      def unconvert_mulitiple_spaces(text)
        text.gsub(/&nbsp;/, " ")
      end
      
      def unconvert_quotes(text)
        text = text.gsub(/<div class='inline-quote'><span class='q'>/,'_"')
        text.gsub(/<\/span><\/div>/,'"_')
      end
      
      def unconvert_line_breaks(text)
        text.gsub( / <br\/> /,"\n" )
      end
      
      def unconvert_sections(text)
        text.gsub(/#{TextEncoder::start_section_encoding}(.*?)#{TextEncoder::end_section_encoding}/,'**\1**\n')
      end
      
      def convert_from_html(text)
        unconvert_links_and_emails(
          unconvert_line_breaks(
            unconvert_quotes(
              unconvert_mulitiple_spaces(text)
        ) ) )
      end
      
    end
    
    module ConvertToPdf
      
      def convert_sections_to_pdf(text)
        convert_section_generically(text,"pdf.select_font('Helvetica') $SEC")
      end
      
      def convert_numbers_to_pdf(text)
        convert_numbers_generically(text,'$NUM')
      end
      
      def convert_to_pdf(text)
        convert_sections_to_pdf(
          convert_numbers_to_pdf(text)
        )
      end
    end
    
    module CreateEncoded
      def encode_bold(text)
        '*'+text.strip+'*'
      end
      
      def encode_link(link,name=nil)
        link =~ /^http:\/\// or link = 'http://'+link
        return name.nil? ? link : %{#{link} (#{name.strip})}
      end
      
      def encode_italics(text)
        '/' + text.strip = '/'
      end
      
      def encode_underline(text)
        '_' + text.strip + '_'
      end
      
      # Make the following text into quote format
      def encode_quotes(text)
      end
      
    end

    extend ConvertToHtml
    extend ConvertToPdf
    extend ConvertFromHtml
    extend CreateEncoded
      
  end

end

if __FILE__ == $0
  
  def convert_numbers_generically    
    text =<<-END
    **Section 1**
    # Step 1
    # Step 2 
    # Step 3
  
    no step
  
    # Step 4

    **Section 2**
    # Step 1
    # Step 2 
    # Step 3
      
    # Step 4
    END
  
    puts TextEncoder.convert_numbers_generically(text)
  end
  
  # 
  def convert_links
    links=[
      "www.basic.com",
      "www.basic.com.",
      "www.basic.com;",
      "http://www.basic.com",
      "https://www.basic.com",
      "http://www.basic.com/path?arg=10",
      "https://www.basic.co.uk/path?arg=10",
      "http://localhost:3000"
      ]
    
    links.each do |link|
      puts [link, " => ",NoPlanB::TextEncoder.convert_links(link) ].join
    end
  end
  
  convert_links
end

