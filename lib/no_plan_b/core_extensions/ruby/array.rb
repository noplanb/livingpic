require 'set'
module NoPlanB
  module ArrayExtensions

    def self.included(base)
      base.send(:include,Transform)
      base.send(:include,Statistics)
      base.send(:include,Shortcuts)
      base.send(:extend,ClassMethods)
    end

    module ClassMethods
      # Given two arrays, make sure their lengths match
      def match_lengths(a,b,filler=nil)
        diff = a.length - b.length
        if diff > 0
          b.fill(filler,b.length,diff)
        elsif diff < 0
          a.fill(filler,a.length,-diff)
        end
      end
    end
    
    module Transform
      def self.included(base)
        base.send(:include,InstanceMethods)
        base.send(:alias_method,:uniq_without_block, :uniq)
        base.send(:alias_method, :uniq, :uniq_with_block)
      end

      module InstanceMethods
        # create a hash from an array of [key,value] tuples
        # you can set default or provide a block just as with Hash::new
        # Note: if you use [key, value1, value2, value#], hash[key] will
        # be [value1, value2, value#]
                                          
        # GARF - renamed from to_hash to to_h
        # This causes problems in activerecord in rails 3.2 even though when I test in the console
        # 
        def to_h(default=nil, &block)
          hash = block_given? ? Hash.new(&block) : Hash.new(default)
          each { |(key, value)| hash[key]=value }
          hash
        end

        def swap!(a,b)
          c = self[a]
          self[a] = self[b]
          self[b] = c
          self
        end

        # The efficient way of doing this is to use sort_by { rand }, but 
        # this assumes the object supports the <=> operator, which is not necessarily the case
        # WARNING - it seems that in ruby 1.8.7 and 1.9 shuffle is defined in the library 
        # so we can take it out of here 
        if !Array.new.respond_to?(:shuffle)
          def shuffle
            self.dup.shuffle!
          end

          def shuffle!
            (size-1).downto(1) { |n| swap!(n, Kernel.rand(size)) }
            self
          end
        end
        
        def randomize
          shuffle
        end
        
        # Return the absolute value for each elements
        # Fails if the array contents are not numerics
        def abs
          self.map { |e| e.abs }
        end

        # Quote each of the entries in the array
        # obviously, everything becomes a string
        def quote
          self.map { |e| "'#{e}'"}
        end
        
        # Convert each element inthe array to a string
        def stringify
          self.map { |e| e.to_s }
        end

        def intify
          self.map { |e| e.to_i }
        end
        
        def floatify
          self.map { |e| e.to_f }
        end
        
        # Divide the array into the number of chunks indicated
        # Example:
        # >> [1,2,3,4,5,6,7].chunk(3)
        # => [[1, 2, 3], [4, 5], [6, 7]]
        # >> [1,2,3,4,5,6,7,8,9].chunk(4)
        # => [[1, 2, 3], [4, 5], [6, 7], [8, 9]]
        # Seems this exists as in_groups in rails core extensions
        def chunk(pieces=2)
          len = self.length;
          mid = (len/pieces)
          chunks = []
          start = 0
          1.upto(pieces) do |i|
            last = start+mid
            last = last-1 unless len%pieces >= i
            chunks << self[start..last] || []
            start = last+1
          end
          chunks
        end

        # Folds the array into a matrix so that the number of columns is 
        # less than or equal to the input parameter
        # The folding pattern is a Z, that is, rows always start at the left
        # Example:
        # >> [1,2,3,4,5,6,7,8,9].fold(4)
        # => [[1, 2, 3, 4], [5, 6, 7, 8], [9]]
        # This exists as in_groups_of..
        def fold(num_cols=2)
          rows = []
          tmp_row = []
          self.each { |e|
            if tmp_row.length % num_cols == 0 
              rows << tmp_row unless tmp_row.empty?
              tmp_row = []
            end
            tmp_row << e
          }
          rows << tmp_row unless tmp_row.empty?
          rows
        end

        # If a block is given, that's what we want to be unique
        # Seems this exists as uniq_by in rails core
        def uniq_with_block
          if ( block_given? )
            seen = Set.new
            self.inject([]) { |r,o| 
              v = yield o
              seen.include?(v) or (seen.add(v)) && r << o
              # puts "v = #{v.inspect}, seen=#{seen.inspect}, r=#{r.length}"
              r
            }
          else
            uniq_without_block
          end
        end

        # ==========
        # = Matrix =
        # ==========

        # Transpose the matrix
        # Since ruby doesn't really have an understanding of matrix, we assume
        # the user has already configured the array correctly to have multiple columns
        # and that it's uniform
        def transpose!
          unless first.is_a?(Array)
            self.replace map { |x| [x] }
          end
          cols = map { |row| row.length}.max
          self.replace inject([]) { |m,row|
            (0...cols).each{ |i| (m[i] ||= []) << row[i]}
            m
          }
        end

        def transpose
          self.dup.transpose!
        end
        
        # Add a column of data to the existing matrix
        # Note that if the matrix is irregular, there is no nil-filling, the column
        # is simply appended in irregular fashion
        def add_column!(column_data)
          unless first.is_a?(Array)
            self.replace map { |x| [x] }
          end
          (0...[length,column_data.length].max).each { |idx| (self[idx] ||= [])<< column_data[idx]}
          self
        end

        def strip_blanks
          if respond_to?(:blank?)
            select { |x| !x.blank? }
          else
            select { |x| 
              !x.nil? && !x.empty? 
            }
          end
        end
      end
    end

    module Shortcuts
      def self.included(base)
        base.send(:include,InstanceMethods)
        base.send(:extend,ClassMethods)
      end
      
      module ClassMethods
        def sequence_to(start,stop,step=1)
          r=[]
          x = start
          raise "sequence_to(start,stop,step): Stop must be greater than start" unless stop > start
          while ( x < stop ) do
             r << x 
             x+= step
          end
          # start.step(stop,step) { |x| r << x }    
          r
        end

        def sequence(start,count,step=1)
          sequence_to(start,start + count*step,step)[0...count]
        end
      end
      
      module InstanceMethods
        # Mapping functions that are analogous to each_with_index
        # That is, the index is passed as the second argument
        def map_with_index!
          each_with_index do |e, idx| self[idx] = yield(e, idx); end
        end

        def map_with_index(&block)
          dup.map_with_index!(&block)
        end

        # Returns the values for a sequence in an array
        # start_index represents the starting index
        # skip represents the numbers to skip
        def skipping_values_at(start_index,skip=1)
          x = []
          (start_index...self.length).step(skip) { |i| x << self[i] }
          x
        end

        def column(column_number)
          map { |row| row[column_number] }
        end

        def sort_by_column(column_number)
          sort_by{ |x| x[column_number]}
        end


        # Try to find the subarray in the indicated array
        # Works like the index command for strings
        # e.g. 
        # [1,2,3,4].subarray_index([1,2]) => 0 
        # [1,2,3,4].subarray_index([3,4]) => 2 
        # [1,2,3,4].subarray_index([4,3]) => nil
        def subarray_index(subarray)
          subarray_length = subarray.length
          found_index = nil
          (0..(length - subarray_length)).each { |index|
            found_index = index and break if self.slice(index,subarray_length) == subarray
          }
          found_index
        end
      end
    end

    module Statistics

      def self.included(base)
        base.send(:alias_method,:max_without_simplification,:max)
        base.send(:alias_method,:max,:max_with_simplification)
        base.send(:alias_method,:min_without_simplification,:min)
        base.send(:alias_method,:min,:min_with_simplification)
      end
      # ==============
      # = Histograms =
      # ==============
      # Returns a hash indexed by the number of occurences
      # and returning the value that occurred that many times
      def bin_by_occurrence(&block)
        k = Hash.new
        histogram(&block).each { |x,i| 
          k[i] = (k[i] || []) << x
        }
        k
      end

      def bin_by(&block)
        k = Hash.new
        each { |x| 
          (k[yield(x)] ||= []) << x
        }
        k    
      end

      def bin_by_count(&block)
        bin_by(&block).map { |x,y| [x,y.length] }
      end


      # ===================
      # = Some statistics =
      # ===================
      # Warning - RAILS  defines sum for type enumerable, which does the same functionality that we would have here
      # except it works for strings also
      def sum_over(method=nil,&block)
        # puts "Array calling sum has length #{self.length} => #{self.inspect}"
        if block_given?
          inject( 0 ) { |sum,x| sum + (yield(x) || 0) }
        elsif method
          inject( 0 ) { |sum,x| sum +  (x.send(method)||0) }
        else
          inject( 0 ) { |sum,x| sum +  (x||0) }
        end
      end

      # This only works if the values are numeric
      # Returns a 2 dimensional array, where the first dimension is the middle value of the 
      # bin and the second is the items that go into that bin
      # input can be: 
      # 1) an integer, defining the number of bins to partition the numbers into
      # 2) an has defining the min, max, and number of divisions to consider  {:min => 0, :max => 10, :n => 10}
      def bin_into(bins,&block)
        if block_given?
          values = self.zip(self.map(&block)).sort_by{ |x| x[1] }      
        else
          values = self.zip(self).sort_by{ |x| x[1] }
        end
        if bins.is_a?(Hash)
          max = bins[:max]
          min = bins[:min]
          n = bins[:n]
        else
          n = bins
        end
        max ||= values.last[1]
        min ||= values.first[1]
        div = (max - min)/(n.to_f)
        binmin = min
        binmax = binmin+div
        binval = (binmax + binmin)/2.0
        index = 0
        bins = (0...n).inject([]) { |s,i|   s<< [binmin+div*i,[]] }
        values.each { |obj,v| 
          while v >= binmax && index < n-1
            index += 1
            binmin = bins[index][0] 
            binmax = binmin + div
          end
          bins[index][1]  << obj
        }
        bins
      end

      def bin_into_count(n,&block)
        bin_into(n,&block).map { |x,y| [x,y.length] }
      end

      def max_by(&proc)
        max = at(0)
        vmax = proc.call(max)
        self.each { |a| v = proc.call(a) ; max,vmax = a,v if v && (!vmax || v > vmax) }
        max
      end

      def min_by(&proc)
        min = at(0)
        vmin = proc.call(min)
        self.each { |a| v = proc.call(a) ; min,vmin = a,v if v && (!vmin || v < vmin) }
        min
      end

      def max_with_simplification(&proc)
        if block_given? && proc.arity == 1
          max_by(&proc)
        else
          max_without_simplification(&proc)
        end
      end

      def min_with_simplification(&proc)
        if block_given? && proc.arity == 1
          min_by(&proc)
        else
          min_without_simplification(&proc)
        end
      end

      def mean(&block)
        sum(&block)/self.size.to_f
      end

      def median(already_sorted=false,&proc)
        return nil if empty?
        if block_given? 
          a = self.map { |v| proc.call(v) }.sort 
        else
          a =  already_sorted ? self : self.sort 
        end
        m_pos = a.size / 2
        return a.size % 2 == 1 ? a[m_pos] : (a[m_pos-1] + a[m_pos])/2.0
      end

      def variance(&block)
        m = self.mean(&block)
        sum = 0.0
        self.each {|x| sum += ((block_given? ? block.call(x) : x)-m)**2 }
        sum/self.size
      end

      def stdev
        Math.sqrt(self.variance)
      end

      def histogram(&block)                                 # => Returns a hash of objects and their frequencies within array.
        k=Hash.new(0)
        if block_given?
          self.each {|x| k[ yield(x) ]+=1 }
        else
          self.each {|x| k[x]+=1 }
        end
        k
      end

      def ^(other)                              # => Given two arrays a and b, a^b returns a new array of objects *not* found in the intersection of both.
        (self | other) - (self & other)
      end

      def freq(x,&block)                               # => Returns the frequency of x within array.
        h = self.histogram(&block)
        h[x]
      end

      def maxcount                              # => Returns highest count of any object within array.
        h = self.histogram
        x = h.values.max
      end

      def mincount                              # => Returns lowest count of any object within array.
        h = self.histogram
        x = h.values.min
      end

      def outliers(x)                           # => Returns a new array of object(s) with x highest count(s) within array.
        h = self.histogram                                                              
        min = self.histogram.values.uniq.sort.reverse.first(x).min
        h.delete_if { |x,y| y < min }.keys.sort
      end

      def zscore(value)                         # => Standard deviations of value from mean of dataset.
        (value - mean) / stdev
      end

    end   # Statistics

  end
end

Array.send(:include,NoPlanB::ArrayExtensions)

if __FILE__ == $0
  puts "Testing sub_array_index"
  puts [1,2,3,4].subarray_index([1,2]) == 0 ? 'OK' : 'ERROR'
  puts [1,2,3,4].subarray_index([3,4]) == 2 ?  'OK' : 'ERROR'
  puts [1,2,3,4].subarray_index([4,3]).nil? ?  'OK' : 'ERROR'
  puts [1,2,3].subarray_index([1,2,3]) == 0 ?  'OK' : 'ERROR'
  puts [2,1,3].subarray_index([1,2,3]) == nil ?  'OK' : 'ERROR'
  puts [2,1,3].subarray_index([1]) == 1 ?  'OK' : 'ERROR'

  puts "testing occurrences"
  a = [1,2,3,3,4,4,5,4,7,2]
  puts "a.histogram == " + a.histogram.to_s
  puts a.histogram[1] == 1 ? 'OK' : 'ERROR'
  puts a.histogram[2] == 2 ? 'OK' : 'ERROR'
  puts a.histogram[3] == 2 ? 'OK' : 'ERROR'
  puts a.histogram[4] == 3 ? 'OK' : 'ERROR'
  puts a.freq(7) == 1 ? 'OK' : 'ERROR'
  puts a.histogram == a.histogram ? 'OK' : 'ERROR'

  puts( (a.bin_by_occurrence[1] - [1,5,7]).empty? ? 'OK' : 'ERROR')
  puts( (a.bin_by_occurrence[2] - [2,3]).empty? ? 'OK' : 'ERROR')
  puts( (a.bin_by_occurrence[3] - [4]).empty? ? 'OK' : 'ERROR')

  puts( (a.bin_by { |x| x%2 == 0})[false].length == 5 ? 'OK' : 'ERROR')

  puts "testing histogram with blocks"
  puts a.freq(4) { |x| x**2 } == 2 ? 'OK' : 'ERROR'
  puts a.freq(1) { |x| x-6 } == 1 ? 'OK' : 'ERROR'

  puts "Testing bin_by_occurrence with blocks"
  puts( (a.bin_by_occurrence { |x| x+1 }[2] - [3,4]).empty? ? 'OK' : 'ERROR')

  puts "Testing uniq with blocks"
  a = [1,2]; b=[1,3]; c=[2,3]
  x = [a,b,c]
  y = x.uniq { |v| v[0] }
  puts y == [[1,2],[2,3]] ? 'OK' : 'ERROR'

  puts "Testing binning with and without blocks"
  # a = [0,5,3,2,7,6,2,8,1,10]
  # puts a.bin_into(2).inspect
  # puts a.bin_into(5).inspect

  b = [0.295918367346939, 0.0816326530612245, 0.719387755102041, 0.198979591836735, 0.688775510204082, 0.21875, 1.0, 0.0, 0.198979591836735, 0.581632653061225, 1.0, 0.306122448979592, 0.612244897959184, 0.183673469387755, 0.403061224489796, 0.125, 0.556122448979592, 0.556122448979592, 0.612244897959184, 0.290816326530612, 0.188775510204082, 0.290816326530612, 0.649305555555556, 1.0, 0.357638888888889, 0.306122448979592, 0.198979591836735, 0.612244897959184, 0.413265306122449, 0.413265306122449, 0.0918367346938776, 0.306122448979592, 0.428571428571429, 0.306122448979592, 0.290816326530612, 0.948979591836735, 0.295918367346939, 0.290816326530612, 0.290816326530612, 0.581632653061225, 0.612244897959184, 0.306122448979592, 0.107142857142857, 0.183673469387755, 0.290816326530612, 1.0, 0.755102040816326, 0.719387755102041, 0.295918367346939, 0.688775510204082, 0.183673469387755, 0.357638888888889, 0.428571428571429, 0.295918367346939, 0.581632653061225, 0.188775510204082, 0.520408163265306, 0.581632653061225, 0.612244897959184, 0.188775510204082, 0.306122448979592, 0.0, 0.295918367346939, 0.0918367346938776, 0.295918367346939, 0.0816326530612245, 0.612244897959184, 0.428571428571429, 0.290816326530612, 0.581632653061225, 0.555555555555556, 0.948979591836735, 0.198979591836735, 0.306122448979592, 0.214285714285714, 0.403061224489796, 0.520408163265306, 0.290816326530612, 0.581632653061225, 0.0816326530612245, 0.290816326530612, 0.306122448979592, 0.948979591836735, 1.0, 0.612244897959184, 0.295918367346939, 0.290816326530612]
  puts b.bin_into_count(10).inspect
  
  puts "Testing Transpose"
  a = [1,2,3,4]
  puts a.transpose! == [[1,2,3,4]] ? 'OK' : 'ERROR'
end


