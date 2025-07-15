class FixParticipationStatusColumn < ActiveRecord::Migration[8.0]
  def change
    change_column :participations, :status, :integer, default: 0
  end
end
