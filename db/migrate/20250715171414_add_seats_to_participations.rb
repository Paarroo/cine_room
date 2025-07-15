class AddSeatsToParticipations < ActiveRecord::Migration[7.0]
  def change
    add_column :participations, :seats, :integer, default: 1, null: false
  end
end