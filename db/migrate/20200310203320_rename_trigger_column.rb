class RenameTriggerColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :triggers, :trigger, :event
  end
end
