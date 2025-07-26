class AddQrCodeTokenToParticipations < ActiveRecord::Migration[8.0]
  def change
    add_column :participations, :qr_code_token, :string
    add_column :participations, :used_at, :datetime
    add_index :participations, :qr_code_token, unique: true
  end
end