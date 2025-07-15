class CreateCreators < ActiveRecord::Migration[8.0]
  def change
    create_table :creators do |t|
      t.references :user, null: false, foreign_key: true
      t.text :bio
      t.integer :status
      t.datetime :verified_at

      t.timestamps
    end
  end
end
