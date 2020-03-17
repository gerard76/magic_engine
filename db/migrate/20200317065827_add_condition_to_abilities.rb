class AddConditionToAbilities < ActiveRecord::Migration[5.0]
  def change
    add_column :abilities, :condition, :json
  end
end
