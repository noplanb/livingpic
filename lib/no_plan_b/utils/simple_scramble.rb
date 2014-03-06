module NoPlanB
  # a super-simple and stupid algorithm for scrambling and unscrambling some text - couldn't be easier to crack - 
  # it's just to provide a thin layer of obscurity
  class SimpleScramble

    SCRAMBLE_CODE_SETS = { 
      :classic => ('a'..'z').to_a + ('A'..'Z').to_a + %w(@ . - , + ! ~ # %) + ('0'..'9').to_a,
      :alphanumeric =>  ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    }
    
    SEP_PATTERNS = {:classic => '.-,', :alphanumeric => 'zlX'}
    @scramble_code_sets = SCRAMBLE_CODE_SETS
    @sep_patterns = SEP_PATTERNS

    class << self
      attr_reader :scramble_code_sets,:scramble_codes, :sep_patterns

      # Specify which set you want to use:
      # options include:
      #  :type  => the set to use (:classic or :alpha)
      #    :alpha => limit it to alphanumeric codes
      #    :classic => our old system for compatibility
      def scramble_basic(text,options={})
        return "" if text.empty?
        type = options[:type] || :classic
        set = scramble_code_sets[type] 
        codes = scramble_codes[type]
        out = ""
        text.each_byte { |i|
          # If the character is present for encoding, then find its location, shift it by text.length, and find the
          # encoding for that shifted character
          loc = set.index(i.chr) ? (set.index(i.chr) + text.length) % set.length : nil
          # puts "loc = #{loc} #{set[loc]}"
          out << (loc ? codes[set[loc]] : i.chr)
        }
        out
      end

      # This is a scrambling pattern that pads the text to obfuscate it even more
      #  :length => pad the text until it reaches this length.  This is only effective if it's bigger than the text length
      #  :add => pad the text with this many characters, if an array, then it represents min and max
      #  :add_range => pad the text with between min and max characters, input must be 2 element array
      #  :input => scrambling input type - affects the type of scrambling that is done
      #    :any => can have any character in it
      #    :alphanumeric => should only have alphanumeric characters in it
      # NOTE: there is sometimes a 3 character separator added to the characters.  This could affect the number of characters
      # that are actually added
      def scramble_with_additions(text,options={})
        text = text.to_s
        sep = get_sep(options[:type])
        n = sep ? sep.length : 0
        if options[:add]
          if options[:add].is_a?(Array)
            fixed = options[:add][0].to_i
            ran = [options[:add][1].to_i - fixed - n,0].max
          else
            fixed = params[:add].to_i
            ran = 0
          end
        elsif options[:length]
          fixed = [options[:length].to_i - text.length - n,0 ].max
          ran = 0
        else
          fixed = 3
          ran = 3
        end
        raise "Input text pattern includes separation pattern: #{text}, #{sep}" if !sep.empty? && text.index(sep)
        scramble_basic(text+sep+random_string(fixed+ran),options)
      end
      alias_method :scramble, :scramble_with_additions

      # Unscramble this - you need to know what type of thing you're unscrambling
      def unscramble(text,options={})
        return "" if text.blank?
        sep = get_sep(options[:type])
        type = options[:type] || :classic
        set = scramble_code_sets[type] 
        codes = scramble_codes[type]
        out = ""
        text.each_byte { |i| 
          # Find the decoding for the encoded character.  If it's present, it's actually for 
          # a different character that is text length away
          loc = codes.index(i.chr) ? set.index(codes.index(i.chr)) : nil
          # puts "#{i.chr} - #{(loc-text.length) % set.length}"
          out << (loc ?  set[(loc-text.length) %  set.length] : i.chr )
        }
        if i=out.index(sep)
          out[0,i]
        else
          out
        end
      end

      # A slightly better algorithm for scrambling the email
      # We pad it with a random number of characters, then scramble it
      def scramble_email(email)
        scramble(email + "-v2-" + random_string(1+rand(8)))
      end

      def unscramble_email(str)
        s = unscramble(str)
        if s =~ /(.+)-v2-.+$/
          s = $1
        end
        s
      end

      def scramble_number(num,options={})
        options[:length] ||= 16
        scramble(num.to_s,options.merge(:type => :alphanumeric))
      end

      def unscramble_number(code)
        x = unscramble(code,:type => :alphanumeric)
        x.to_i.to_s == x ? x.to_i : nil
      end

      # Encodes the number by scrambling it, converting it to hex, and embedding it into a string of the indicated length
      def encode_number(number,string_length=16)
        a = Array.new(string_length)
        # randomly place the valid digits into a string
        sn = mix_number(number).to_s(16).upcase
        # puts "scrambled number = #{sn}"
        positions = []
        # Find where to put the scrambled number
        until positions.length == sn.length
          i = rand(string_length) 
          positions << i unless positions.include?(i)
        end
        positions.sort.each_with_index { |p,i| a[p] = sn[i].chr }
        # Now fill in the rest w/ cruft
        for i in 0...string_length do 
          a[i] ||= random_filler
        end
        a.to_s
      end

      # extracts a number from an encoded string
      def extract_number(s)
        hex_string = []
        s.each_byte { |char| 
          hex_string << char.chr if hex_values.include?(char.chr)
        }
        encoded_number = hex_string.to_s.to_i(16)
        unmix_number(encoded_number.to_s)
      end
      alias_method :unencode_number, :extract_number

      private 

      def scramble_code_sets
        @scramble_code_sets || SCRAMBLE_CODE_SETS
      end
      
      def sep_patterns
        @sep_patterns || SEP_PATTERNS
      end
      
      def scramble_codes
        @scramble_codes ||= generate_all_scramble_codes
      end
      
      def get_sep(input_type)
        case input_type
        when :any then sep_patterns[:classic]
        when :alphanumeric then sep_patterns[:alphanumeric]
        when :numeric then sep_patterns[:numeric]
        else sep_patterns[:classic]
        end
      end

      def generate_all_scramble_codes
        @scramble_codes = {}
        scramble_code_sets.each do |key,set|
          @scramble_codes[key] = generate_scramble_codes(set)
        end
        @scramble_codes
      end

      # This rather cryptic function creates a random permutation of the 
      # values
      def generate_scramble_codes(set)
        # logger.mark("Generating the random number map for SimpleScramble")
        srand(48)
        cmap = {}
        set.each { |letter|
          while ( true )
            i = rand(set.length)
            next if( cmap[set[i]] )
            cmap[set[i]] = letter
            break
          end
        }
        srand
        cmap
      end

      # =================================
      # = Just for scrambling numbers!! =
      # =================================
      # Scrambles a number and returns a different number
      def mix_number(number)
        x = []
        number.to_s.each_byte { |digit| 
          x << numbers_map[digit.chr.to_i]
        }
        x.to_s.to_i
      end

      # Unscrambles a number and returns a number
      def unmix_number(input)
        x = []
        input.to_s.each_byte { |digit|
          x << numbers_map.index(digit.chr.to_i)
        }
        x.to_s.to_i
      end

      # Note: 0 has to map to 0
      def numbers_map()
        [0,3,7,2,9,4,8,6,5,1]
      end

      def hex_values
        @hex ||= %w(0 1 2 3 4 5 6 7 8 9 A B C D E F)
      end

      def fillers
        @fillers ||= ("G".."Z").to_a + ("a".."z").to_a
      end

      def random_filler
        fillers[rand(fillers.length)]
      end

      private

      def random_string(length,charset=nil)
        charset ||= ('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a
        a = []
        length.times { a << charset[rand(charset.length)] } 
        a.join
      end    
    end

    # Now generate all the scramble codes!
    generate_all_scramble_codes
  end

  # puts SimpleScramble.unscramble(SimpleScramble.scramble("test")) 
  # puts SimpleScramble.unscramble(SimpleScramble.scramble("bubba")) 
  # puts SimpleScramble.unscramble(SimpleScramble.scramble("22jk33")) 

  if __FILE__ == $0 
    puts "Now testing number standard scrambling"
    raise "Encoding error" if SimpleScramble.scramble('me@you.com') == SimpleScramble.scramble('me@you.com')
    raise "Scrambling error " unless SimpleScramble.unscramble(SimpleScramble.scramble("aa")) == 'aa'
    raise "Scrambling error " unless SimpleScramble.unscramble(SimpleScramble.scramble("test")) == 'test'
    raise "Scrambling error " unless SimpleScramble.unscramble(SimpleScramble.scramble("something")) == 'something'
    raise "Scrambling error " unless SimpleScramble.unscramble(SimpleScramble.scramble("234kjsf")) == '234kjsf'
    raise "Scrambling error " unless SimpleScramble.unscramble(SimpleScramble.scramble_basic("234kjsf")) == '234kjsf'
    raise "Email Scrambling error " unless SimpleScramble.unscramble_email(SimpleScramble.scramble_email("bubba@foo.dom")) == 'bubba@foo.dom'
    10.times do 
      s = SimpleScramble.send :random_string,10+rand(20)
      raise "Scrambling error " unless SimpleScramble.unscramble(SimpleScramble.scramble(s)) == s
      raise "Scrambling error " unless SimpleScramble.unscramble(SimpleScramble.scramble_basic(s)) == s
    end

    puts "Now testing number scrambling"
    2000.times do
      n=rand(1000)
      s = SimpleScramble.scramble_number(n,:length => 10)
      n2 = SimpleScramble.unscramble_number(s)
      # puts "s = #{s}, s.length = #{s.length}, n=#{n}, n2=#{n2}"
      raise "Number Scrambling error " unless n2 == n
    end

    puts "Now bogus string unscrambling to a number"
    2000.times do 
      s = SimpleScramble.send :random_string,16
      raise "Numbe bogus string unscrambling error" unless SimpleScramble.unscramble_number(s).nil?
    end

    #    Test that numbers encode correctly
    puts "Now testing old style number encoding"
    200.times do 
      num=rand(2000)
      s= SimpleScramble.encode_number(num)
      unencoded = SimpleScramble.extract_number(s)
      # puts "n=#{num}, scrambled = #{s}, unencoded=#{unencoded}"
      raise "Number encoding error" if num != unencoded
    end

  end

end