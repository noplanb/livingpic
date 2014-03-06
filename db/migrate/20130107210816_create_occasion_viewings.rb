class CreateOccasionViewings < ActiveRecord::Migration
  def change
    create_table :occasion_viewings do |t|
      t.integer :user_id
      t.integer :occasion_id
      t.datetime :time
    end
    add_index :occasion_viewings, :user_id
    
  end
end
