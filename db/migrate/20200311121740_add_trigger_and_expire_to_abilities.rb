class AddTriggerAndExpireToAbilities < ActiveRecord::Migration[5.0]
  def change
    add_column :abilities, :trigger, :json
    add_column :abilities, :expire,  :json
  end
end
