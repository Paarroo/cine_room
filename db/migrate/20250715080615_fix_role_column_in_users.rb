class FixRoleColumnInUsers < ActiveRecord::Migration[8.0]
  def change
    change_column :users, :role, :integer, default: 0
    add_index :users, :role unless index_exists?(:users, :role)
  end
end
