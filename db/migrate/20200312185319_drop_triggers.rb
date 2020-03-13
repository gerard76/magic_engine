class DropTriggers < ActiveRecord::Migration[5.0]
  def change
    drop_table :triggers
  end
end
