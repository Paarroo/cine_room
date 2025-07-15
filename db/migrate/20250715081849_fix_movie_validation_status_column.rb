class FixMovieValidationStatusColumn < ActiveRecord::Migration[8.0]
  def change
    change_column :movies, :validation_status, :integer, default: 0
  end
end
