class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.references :user, :index => true
      t.float :longitude
      t.float :latitude
      t.references :occasion, :index => true
      t.attachment :pic
      t.datetime :time

      t.timestamps
    end

    add_index :photos, :user_id
    add_index :photos, :occasion_id
    
  end
end
