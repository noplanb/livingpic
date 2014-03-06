class CreateLikes < ActiveRecord::Migration
  def change
    create_table :likes do |t|
      t.integer :user_id
      t.integer :photo_id
      t.datetime :created_on
    end
    add_index :likes, :user_id
    add_index :likes, :photo_id
  end
end
