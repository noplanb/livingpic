class AddCaptionToPhoto < ActiveRecord::Migration
  def change
    add_column :photos, :caption, :string
    add_column :photos, :aspect_ratio, :float
  end
end
