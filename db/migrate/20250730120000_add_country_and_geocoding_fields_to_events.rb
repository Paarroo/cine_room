class AddCountryAndGeocodingFieldsToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :country, :string
    add_column :events, :geocoding_confidence, :decimal, precision: 5, scale: 2
    add_column :events, :coordinates_verified, :boolean, default: false, null: false
    
    # Add indexes for better query performance
    add_index :events, :country
    add_index :events, :coordinates_verified
    add_index :events, :geocoding_confidence
  end
end