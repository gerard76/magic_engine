class OneEffectPerAbility < ActiveRecord::Migration[5.0]
  def change
    rename_column :abilities, :effects, :effect
  end
end
