class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :movie, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.integer :rating
      t.text :comment

      t.timestamps
    end

    add_index :reviews, [ :user_id, :movie_id, :event_id ], unique: true, name: 'index_reviews_on_user_movie_event'
    add_index :reviews, :rating
  end
end
