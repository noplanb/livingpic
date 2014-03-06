class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.references :recipient
      t.references :occasion
      t.references :trigger, :polymorphic => true
      t.references :contact_detail                  # if the contact is based upon a detail mark it here
      t.string :contact_value, :limit => 50
      t.string :kind, :index => true
      t.string :template_id
      t.string :status, :limit => 20
      t.string :ext_id, :limit => 50
      t.string :hash_code, :limit => 15
      t.timestamps
    end

    add_index :notifications, :occasion_id
    add_index :notifications, :kind
    add_index :notifications, [:trigger_type, :trigger_id]
    add_index :notifications, :hash_code
    add_index :notifications, :recipient_id
    add_index :notifications, :status
  end
end
