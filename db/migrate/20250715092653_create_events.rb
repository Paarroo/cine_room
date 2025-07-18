class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :movie, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :venue_name, null: false
      t.string :venue_address, null: false
      t.date :event_date, null: false
      t.time :start_time, null: false
      t.integer :max_capacity, null: false
      t.integer :price_cents, null: false
      t.integer :status, default: 0, null: false
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.timestamps
    end

    add_index :events, :status
    add_index :events, :event_date
    add_index :events, [ :latitude, :longitude ]
  end
end
