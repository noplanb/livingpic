# "string".recognized_as?(:email)
# and 
# 'string'.recognize which should return what it recognized
# and also later include 
# 'string'.recognize_in
# which should return all the items it recognized inside, with their positions inside the string

module NoPlanB
  module TextUtils
    # Check if the indicated item is a link
    extend self

    VALID_OBJECTS = [:email,:link] unless defined? VALID_OBJECTS

    # Makes double_quotes single quotes in a string.
    def single_quote(string)
      string.gsub(/"/,"'")
    end

    def recognized_as_link?(text)
      return (text =~ %r{((www\.|(http|https)+\:\/\/)[_.a-z0-9-]+\.[a-z0-9\/_:@=.+?,##%&~-]*[^.|\'|\# |!|\(|?|,| |>|<|;|\)])}  ) != nil
    end

    def recognized_as_email?(text)
      return !!(text =~ NpbConstants::EMAIL_VALIDATION)
    end

    def recognized_as?(text,what)
      case what
      when :link
        recognized_as_link?(text)
      when :email
        recognized_as_email?(text)
      end
    end

    # restrictions can be :numeric, :alphanumeric, or :alpha
    def random_string(length,restrictions= :alphanumeric)
      valid_chars = ( [:alpha, :alphanumeric].include?(restrictions) ? ('a'..'z').to_a +  ('A'..'Z').to_a : [] ) + 
      ( [:alphanumeric,:numeric].include?(restrictions)  ? (0..9).to_a : [] )
      a = []
      length.times { a << valid_chars[rand(valid_chars.length)] } 
      a.join
    end

    # Remove all parenthesized content and return it in a parens array, along with the 
    # line with the extracted parents as an array (parens, line)
    def extract_parens(line)
      parens = []
      while ( m=line.match( /\((.*?)\)/ ) )
        parens << m[1]
        line = m.pre_match + m.post_match
      end
      return [parens,line]
    end

    # Splits the line into parenthesis, returning an array 
    # [line, true if within parens]
    def split_parens(line)
      lines = []
      while ( m=line.match(/\(([^)]*)\)/) )
        lines << {:text => m.pre_match,:parens => false} unless m.pre_match.empty?
        lines << {:text => m[1],:parens => true}
        line = m.post_match
      end
      lines <<  {:text => line,:parens => false} unless line.empty?
      lines
    end

    def split_and_prepend(content,options={})
      length=options[:line_length] || 40
      prepend = options[:prepend] || '> '
      new_lines = [];
      lines = content.is_a?(String) ? content.split("\n") : content
      lines.each { |line|
        x = 0
        # As we split, we keep the indentation the same
        indent = line.index(/\S/) || 0
        while ( line.length > length ) 
          # Make sure to not break the line up in the middle of a word - only on spaces
          if ( /\s/.match(line[length,1]) ) 
            new_lines.push(line.slice(0,length));
            line = line[length..-1];
          elsif (n = line[0,length].rindex(/\s/) ) 
            new_lines.push(line.slice(0,n));
            line = line[n..-1]
          else
            line = line.slice(0,length)
          end
          line = line.gsub(/^\s+/,'');
          line = ' '*indent + line;
          x = x+1;
        end
        new_lines.push(line) if ( line.length && line.length <= length ) 
      }
      return new_lines.map { |line| prepend + line }.join("\n")

    end

    # Sort the various snippets based upon their relevance to the original one
    # If a block is given, then derive the actual snippets based upon acting on the 
    # the given comparitors
    # if the option {:trim} is given, then we only limit to those
    # elements that score greater than 0
    def sort_by_relevance(main_string,candidates,options={})
      by_similarity = candidates.map{ |c| [main_string.similarity_to(block_given? ? yield(c) : c),c ]}
      by_similarity = by_similarity.select { |x| x[0] > 0 } if options[:trim]
      by_similarity.sort{ |a,b| b[0] <=> a[0]}.map { |x| x[1] }
    end
  end
  

end

if __FILE__ == $0
  puts TextUtils.random_string(20,:alpha)
  x = (1..20).to_a
  r = TextUtils.bin(x,{:steps => 25}) {|x| x*2 }
  puts "#{r.length}: #{r.inspect}"


  puts TextUtils.split_parens("This is (a test) of (all) else").inspect
  puts TextUtils.split_parens("(a test)  (all) of parens").inspect
  puts TextUtils.split_parens("No parens here").inspect
  puts TextUtils.split_parens("(Only parens here)").inspect

  text =<<-END
  Barack Obama's chief strategist leveled the campaign's harshest counterattack yet over John McCain's recent rhetoric on national security issues, and defended himself against charges that threaten to make him a focus of the campaign tit-for-tat in the coming months.

  In a wide-ranging interview on Wednesday with The Huffington Post, David Axelrod began with a bit of political thunder, accusing McCain of failing to question the White House as it used "deception and propaganda to essentially lead America to war."

  "What does all his experience get us?" asked Obama's strategic guru. "What do all those visits [to Iraq] get us?"
  END
  x = TextUtils.split_and_prepend(text)

  puts TextUtils.sort_by_relevance("One two three four",["one two","five","three", "nine", "two three four"])
  # puts x.inspect

end
