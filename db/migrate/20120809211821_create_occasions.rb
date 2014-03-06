class CreateOccasions < ActiveRecord::Migration
  def change
    create_table :occasions do |t|
      t.references :user
      t.string :name
      t.float :longitude
      t.float :latitude
      t.datetime :start_time
      t.datetime :end_time
      t.string :city, :limit => 50
      t.timestamps
    end

    add_index :occasions, :user_id
  end
end
