class CreateTriggers < ActiveRecord::Migration[5.0]
  def change
    create_table :triggers do |t|
      t.belongs_to :card
      t.string :trigger
      t.string :ability
    end
  end
end
