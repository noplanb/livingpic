class AddPushToken < ActiveRecord::Migration
  def up
    # Adding this to users and not devices because per apple documentation, it could change, so you need to re-establish it every session anyway
    add_column :users, :push_token, :string
    remove_column :users, :push_enabled
  end

  def down
    remove_column :users, :push_token
    add_column :users, :push_enabled, :boolean
  end
end
