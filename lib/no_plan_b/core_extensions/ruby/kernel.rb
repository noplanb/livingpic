module Kernel

  def Boolean(var)
    case var.class.to_s
    when 'String'then var.strip! =~ /(\d+)/ ? Boolean($1.to_i) : var =~ /^(true|yes)$/i ? true : false
    when 'Fixnum'then var != 0
    when 'TrueClass'then true
    when 'FalseClass'then false
    else
      false
    end || false
  end

end

if __FILE__ == $0
  [
  "Boolean(0) == false", 
  "Boolean(1) == true" ,
  "Boolean(-1) == true",
  "Boolean('true') == true" ,
  "Boolean('TRUE') == true" ,
  "Boolean('false') == false",
  "Boolean('FALSE') == false",
  "Boolean(true) == true",  
  "Boolean(false) == false",
  "Boolean('yes') == true",
  "Boolean('no') == false"
  ].each { |test|
    eval(test) or raise("Error in '#{test}'")
  }
  puts "All tests completed successfully"
end