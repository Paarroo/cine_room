class FixCreatorStatusColumn < ActiveRecord::Migration[8.0]
  def change
    change_column :creators, :status, :integer, default: 0
  end
end
