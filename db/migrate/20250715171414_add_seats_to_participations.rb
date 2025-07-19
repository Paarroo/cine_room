class ChangeCreatorIdToUserIdInMovies < ActiveRecord::Migration[8.0]
  def change
    rename_column :movies, :creator_id, :user_id

    remove_foreign_key :movies, :creators if foreign_key_exists?(:movies, :creators)
    add_foreign_key :movies, :users, column: :user_id
  end
end
