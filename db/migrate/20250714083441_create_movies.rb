class CreateMovies < ActiveRecord::Migration[8.0]
  def change
    create_table :movies do |t|
      t.string :title
      t.text :synopsis
      t.string :director
      t.integer :duration
      t.string :genre
      t.string :language
      t.integer :year
      t.string :trailer_url
      t.string :poster_url

      t.timestamps
    end
  end
end
