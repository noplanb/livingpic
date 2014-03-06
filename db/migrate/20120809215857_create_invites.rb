class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.references :occasion
      t.integer :inviter_id
      t.integer :invitee_id

      t.timestamps
    end
    add_index :invites, :occasion_id
    add_index :invites, :inviter_id
    add_index :invites, :invitee_id
  end
end
