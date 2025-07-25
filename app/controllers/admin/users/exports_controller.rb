class Admin::Users::ExportsController < Admin::ApplicationController
  
  def show
    respond_to do |format|
      format.csv do
        csv_data = generate_users_csv
        send_data csv_data, 
                  type: 'text/csv',
                  filename: "users_export_#{Date.current.strftime('%Y%m%d')}.csv"
      end
      format.json do
        users_data = User.select(:id, :email, :first_name, :last_name, :role, :created_at)
                        .limit(1000)
                        .map(&:attributes)
        
        render json: {
          success: true,
          data: users_data,
          filename: "users_export_#{Date.current.strftime('%Y%m%d')}.csv"
        }
      end
    end
  end

  private

  def generate_users_csv
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Email', 'First Name', 'Last Name', 'Role', 'Created At']
      
      User.find_each do |user|
        csv << [
          user.id,
          user.email,
          user.first_name,
          user.last_name,
          user.role,
          user.created_at
        ]
      end
    end
  end
end