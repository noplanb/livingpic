# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#

# we use the system user as the source for notifications from the system.  The mobile number should be filled
system = User.create(:first_name => APP_CONFIG[:site_name], :last_name => "System", :mobile_number => "", :email => APP_CONFIG[:admin_email], :status => :active, :password => "ohno88") unless User.find_by_last_name "system"

farhad = User.create(:first_name => "Farhad", :last_name => "Farzaneh", :mobile_number => "+14156020256", :email => "ff@onebeat.com", :status => :active, :password => "ohno88") unless User.find_by_last_name "Farzaneh"

sani = User.create(:first_name => "Sani", :last_name => "ElFishawy", :mobile_number => "+16502453537", :email => "sani@sbcglobal.net", :status => :active, :password => "ohno88") unless User.find_by_last_name "Elfishawy"

