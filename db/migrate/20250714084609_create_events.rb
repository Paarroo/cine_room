class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :movie, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :venue_name
      t.string :venue_address
      t.date :event_date
      t.time :start_time
      t.integer :max_capacity
      t.integer :price_cents
      t.string :status

      t.timestamps
    end
  end
end
