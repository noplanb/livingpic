class AddPhotoMeta < ActiveRecord::Migration
  def up
    add_column :photos, :pic_meta,    :text
  end

  def down
    remove_column :photos, :pic_meta
  end
end
