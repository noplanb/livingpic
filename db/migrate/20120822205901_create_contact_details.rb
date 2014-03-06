class CreateContactDetails < ActiveRecord::Migration
  def change

    create_table :contact_records do |t|
      t.integer :user_id
      t.integer :source_id
      t.string :first_name, :limit => 50
      t.string :last_name, :limit => 50
    end    

    add_index :contact_records, :user_id
    add_index :contact_records, :first_name
    add_index :contact_records, :last_name
    
    create_table :contact_details do |t|
      t.integer :contact_record_id
      t.string :field_name, :limit => 50
      t.string :field_value, :limit => 150
      t.string :kind, :limit => 50
      t.integer :country_code
      t.string :value, :limit => 50
      t.string :status, :limit => 30

      t.timestamps
    end
    
    add_index :contact_details, :contact_record_id
    add_index :contact_details, :kind
    add_index :contact_details, :value
    add_index :contact_details, :status
  end
end
