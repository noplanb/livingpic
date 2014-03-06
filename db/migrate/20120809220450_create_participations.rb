class CreateParticipations < ActiveRecord::Migration
  def change
    create_table :participations do |t|
      t.references :occasion
      t.references :user, :index => true
      t.references :indication, :polymorphic => true, :index => true
      t.string :kind      
      t.timestamps
    end
    add_index :participations, :occasion_id
    add_index :participations, :user_id
    add_index :participations, [:indication_type,:indication_id]
  end
end
