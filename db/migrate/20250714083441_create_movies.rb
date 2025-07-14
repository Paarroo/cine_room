class CreateMovies < ActiveRecord::Migration[8.0]
  def change
    create_table :movies do |t|
      t.string :title
      t.text :synopsis
      t.references :creator, null: false, foreign_key: true
      t.integer :duration
      t.string :genre
      t.string :language
      t.integer :year
      t.string :trailer_url
      t.string :poster_url
      t.integer :validation_status, default: 0, null: false
      t.references :validated_by, foreign_key: { to_table: :users }, null: true
      t.datetime :validated_at

      t.timestamps
    end

    add_index :movies, :creator_id
    add_index :movies, :validation_status
    add_index :movies, :validated_by_id
  end
end
