class AddUserNotificationPreference < ActiveRecord::Migration
  def up
    add_column :users, :notification_preference, :string, :limit => 20
  end

  def down
    remove_column :users, :notification_preference
  end
end
