class CreateCreators < ActiveRecord::Migration[8.0]
  def change
    create_table :creators do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :bio
      t.integer :status, default: 0, null: false
      t.datetime :verified_at
      t.timestamps
    end

    add_index :creators, :status
  end
end
