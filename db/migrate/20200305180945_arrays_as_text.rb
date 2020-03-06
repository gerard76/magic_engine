class ArraysAsText < ActiveRecord::Migration[5.0]
  def change
    change_column :cards, :types,      'text[] USING types::text[]', default: []
    change_column :cards, :supertypes, 'text[] USING supertypes::text[]', default: []
    change_column :cards, :subtypes,   'text[] USING subtypes::text[]', default: []
  end
end
