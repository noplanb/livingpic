codes = {}

while x = gets
  if m = x.match(%r{^(.+)\s\w+ / \w+\s+([\d\s]+) })
    code = m[2].gsub(' ','')
    codes[code] = m[1]
  end
end

puts codes.inspect