namespace :cc do
  
 task :parse do
   File.readlines("lib/country_codes/raw_list").each do |line|
     two_letter = line.match(/Value="(\w+)"/)[1].strip
     
     match_data = line.match( /data-dialcode="(\d+)">(.*)\(+/ )
     dial_code = match_data[1].strip
     country = match_data[2].strip
     puts %{  ["#{two_letter}", "#{dial_code}", "#{country}"],}
   end
   
   
 end

end