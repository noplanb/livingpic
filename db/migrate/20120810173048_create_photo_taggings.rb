class CreatePhotoTaggings < ActiveRecord::Migration
  def change
    create_table :photo_taggings do |t|
      t.references :photo, :index => true
      t.references :tagger, :index => true
      t.references :taggee, :index => true
      # These represent the top-left and bottom-right coordinates identifying the user's face, if and when we get there
      t.integer :tlx
      t.integer :tly
      t.integer :brx
      t.integer :bry
      t.timestamps
    end

    add_index :photo_taggings, :photo_id
    add_index :photo_taggings, :tagger_id
    add_index :photo_taggings, :taggee_id
  end
end
