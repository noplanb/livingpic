class Fixnum
  # Prints a number such as 12345 as 12,345
  def pp(delimiter=",")
    self.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
  end
  
  def dash_for_0(txt="-")
    self == 0 ? txt : self
  end
  
end

if __FILE__ == $0
  puts 1000.pp
  puts 1101.pp
  puts 999.pp
  puts 12345.pp
  puts 1234567.pp
end