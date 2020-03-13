class AddExpireToTriggers < ActiveRecord::Migration[5.0]
  def change
    add_column :triggers, :expire, :string
  end
end
