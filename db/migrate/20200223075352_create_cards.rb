class CreateCards < ActiveRecord::Migration[5.0]
  def change
    create_table :cards do |t|
      t.string  :name
      t.integer :multiverse_id
      t.string  :layout
      t.string  :names, array: true
      t.string  :mana_cost
      t.integer :cmc
      t.string  :colors, array: true
      t.string  :color_identity, array: true
      t.string  :card_type
      t.string  :types, array: true
      t.string  :supertypes, array: true
      t.string  :subtypes, array: true
      t.string  :rarity
      t.string  :text
      t.string  :flavor
      t.string  :artist
      t.string  :number
      t.string  :power
      t.string  :toughness
      t.string  :loyalty
      t.string  :variations
      t.string  :watermark
      t.string  :border
      t.string  :timeshifted
      t.string  :hand
      t.string  :life
      t.string  :reserved
      t.string  :release_date
      t.string  :starter
      t.string  :rulings
      t.string  :foreign_names
      t.string  :printings
      t.string  :original_text
      t.string  :original_type
      t.string  :legalities
      t.string  :source
      t.string  :image_url
      t.string  :set
      t.string  :set_name
    end
  end
end
