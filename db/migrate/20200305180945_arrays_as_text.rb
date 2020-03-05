class ArraysAsText < ActiveRecord::Migration[5.0]
  def change
    change_column :cards, :types,      'text[] USING types::text[]'
    change_column :cards, :supertypes, 'text[] USING supertypes::text[]'
    change_column :cards, :subtypes,   'text[] USING subtypes::text[]'
  end
end
