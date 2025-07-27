class AddGeocodingStatusToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :geocoding_status, :string, default: 'pending'
    add_index :events, :geocoding_status
  end
end
