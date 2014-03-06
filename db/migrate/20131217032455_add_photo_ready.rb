class AddPhotoStatus < ActiveRecord::Migration
  def up
    add_column :photos, :status, :integer
  end

  def down
    remove_column :photos, :status
  end
end
