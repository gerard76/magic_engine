class CreateAbilities < ActiveRecord::Migration[5.0]
  def change
    create_table :abilities do |t|
      t.belongs_to :card
      t.json  :cost
      t.json  :effects
    end
  end
end
