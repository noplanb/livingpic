namespace :contact do
  desc "Used for converting a contact list csv to json for test purposes."
  task :import_csv => :environment do
    require 'csv'
    
    Dir.chdir("#{Rails.root}/lib/tasks/contact_list_test_data/data")
    csv_arr = CSV.read("short.csv")
    header_row = csv_arr[0]
    
    # These are the columns we care about - name, phone, email
    relevant_cols = ["Name", "Given Name", "Family Name"]
    (1..4).each do |n|
      ["Type", "Value"].each do |tv|
        relevant_cols << "Phone #{n} - #{tv}"
        relevant_cols << "E-mail #{n} - #{tv}"
      end
    end
    
    def translate_col_name(col_name)
      case col_name
      when "Given Name"; "first_name" 
      when "Family Name"; "last_name"
      when "Name"; "fullname"
      else  col_name
      end
    end
          
    # Get the column indexes for the relevant columns
    RELEVANT_COL_INDEXES = {}
    header_row.each_with_index do |col_name, i|
      RELEVANT_COL_INDEXES[col_name] = i if relevant_cols.include?(col_name)
    end
    
    def col_for(col_name)
      RELEVANT_COL_INDEXES[col_name.to_s.humanize.capitalize_words]
    end
    
    result = []
    #  Pull out the relevant col data from the rows in the csv
    csv_arr[1..-1].each_with_index do |row, i|
      hsh = {}
      hsh["id"] = i
      RELEVANT_COL_INDEXES.keys.each do |key|
        hsh[translate_col_name(key)] = row[RELEVANT_COL_INDEXES[key]]
      end
      result << hsh
    end
    
    cordova_format = []
    csv_arr[1..-1].each_with_index do |row, i|
      record = {}
      record[:id] = i
      record[:displayName] = row[col_for(:Name)]
      
      record[:name] = {}
      record[:name][:givenName] = row[col_for(:Given_name)]
      record[:name][:familyName] = row[col_for(:Family_Name)]
      record[:name][:formatted] = row[col_for(:Name)]
      
      record[:emails] = []
      (1..4).each do |n|
        type = row[col_for("E-mail #{n} - Type")]
        value = row[col_for("E-mail #{n} - Value")]
        unless type.blank? && value.blank?
          email = {}
          email[:type] = type.to_s.downcase
          email[:value] = value
          record[:emails] << email
        end
      end
      
      record[:phoneNumbers] = []
      (1..4).each do |n|
        type = row[col_for("Phone #{n} - Type")]
        value = row[col_for("Phone #{n} - Value")]
        unless type.blank? && value.blank?
          phone = {}
          phone[:type] = type.to_s.downcase
          phone[:value] = value
          record[:phoneNumbers] << phone
        end
      end
      cordova_format << record
    end
        
    names_only = []
    result.each_with_index do |row, i|
      names_only << {"id" => i, "first_name" => row["first_name"], "last_name" => row["last_name"], "fullname" => row["fullname"]}
    end
    
    file = File.open("names.json", "w")
    file.puts names_only.to_json
    file.close
    
    file = File.open("name_phone_email.json", "w")
    file.puts result.to_json
    file.close    
    
    file = File.open("cordova_format.json", "w")
    file.puts cordova_format.to_json
    file.close    
    
    puts names_only.length
  end
end 
