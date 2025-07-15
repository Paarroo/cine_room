class CreateMovies < ActiveRecord::Migration[8.0]
  def change
    create_table :movies do |t|
      t.references :creator, null: false, foreign_key: true
      t.string :title
      t.text :synopsis
      t.string :director
      t.integer :duration
      t.string :genre
      t.string :language
      t.integer :year
      t.string :trailer_url
      t.string :poster_url
      t.integer :validation_status
      t.references :validated_by, null: false, foreign_key: true
      t.datetime :validated_at

      t.timestamps
    end
  end
end
