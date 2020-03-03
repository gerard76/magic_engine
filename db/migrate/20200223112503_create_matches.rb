class CreateMatches < ActiveRecord::Migration[5.0]
  def change
    create_table :matches do |t|
      t.integer :deck_us
      t.integer :desc_them
      t.string :draw_us
      t.string :draw_them
      t.string :actions # tap play activate
    end
  end
end
