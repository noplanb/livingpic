class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.integer :user_id
      t.integer :photo_id
      t.text :body
      t.datetime :created_on
    end
    add_index :comments, :user_id
    add_index :comments, :photo_id
  end
end
