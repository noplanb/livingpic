class AddContentTimestampToOccasion < ActiveRecord::Migration
  def change
    add_column :occasions, :content_updated_on, :datetime
  end
end
