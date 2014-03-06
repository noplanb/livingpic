class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name, :limit => 50
      t.string :last_name, :limit => 50
      t.string :password, :limit => 20
      t.string :mobile_number, :limit => 20
      t.string :email, :limit => 50
      t.string :status, :limit => 20
      t.string :auth_token, :limit => 50
      t.string :type, :limit => 15
      t.string :campaign, :limit => 50
      t.string :app_version, :limit => 75
      t.boolean :push_enabled
      t.datetime :registered_on
      t.datetime :last_active_on
      t.timestamps
    end

    add_index :users, :status
    add_index :users, :mobile_number
    add_index :users, :first_name
    add_index :users, :last_name
    add_index :users, :auth_token
  end
end
