class FixEventStatusColumn < ActiveRecord::Migration[8.0]
  def change
    change_column :events, :status, :integer, default: 0
  end
end
