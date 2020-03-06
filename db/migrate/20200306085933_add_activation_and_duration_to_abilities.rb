class AddActivationAndDurationToAbilities < ActiveRecord::Migration[5.0]
  def change
    add_column :abilities, :activation, :string
    add_column :abilities, :duration,   :json
  end
end
