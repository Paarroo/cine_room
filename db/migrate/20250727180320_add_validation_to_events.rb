class AddValidationToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :validation_status, :integer, default: 0, null: false
    add_reference :events, :created_by, null: true, foreign_key: { to_table: :users }
    add_reference :events, :validated_by, null: true, foreign_key: { to_table: :users }
    add_column :events, :validated_at, :datetime
    
    # Set default values for existing events
    reversible do |dir|
      dir.up do
        # Mark existing events as approved and set admin as creator
        admin_user = User.find_by(role: 'admin')
        if admin_user
          Event.update_all(
            validation_status: 1, # approved
            created_by_id: admin_user.id,
            validated_by_id: admin_user.id,
            validated_at: Time.current
          )
        end
      end
    end
  end
end
