class CreateMovies < ActiveRecord::Migration[8.0]
  def change
    create_table :movies do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :synopsis, null: false
      t.string :director, null: false
      t.integer :duration, null: false
      t.string :genre, null: false
      t.string :language, default: 'fr'
      t.integer :year, null: false
      t.string :trailer_url
      t.string :poster_url
      t.integer :validation_status, default: 0, null: false
      t.references :validated_by, foreign_key: { to_table: :users }, null: true
      t.datetime :validated_at
      t.timestamps
    end

    add_index :movies, :validation_status
    add_index :movies, :genre
  end
end
