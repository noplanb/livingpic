class CreateOccasionPopEstimates < ActiveRecord::Migration
  def change
    create_table :occasion_pop_estimates do |t|
      t.references :occasion
      t.references :user
      t.integer :value

      t.timestamps
    end

    add_index :occasion_pop_estimates, :occasion_id
    add_index :occasion_pop_estimates, :user_id
  end
end
