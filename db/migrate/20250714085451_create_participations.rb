class CreateParticipations < ActiveRecord::Migration[8.0]
  def change
    create_table :participations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.string :stripe_payment_id
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :participations, [ :user_id, :event_id ], unique: true
    add_index :participations, :status
  end
end
