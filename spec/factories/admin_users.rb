FactoryBot.define do
  factory :admin, class: 'User' do
    email { "admin@cineroom.com" }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { "Admin" }
    last_name { "User" }
    bio { "Administrateur de la plateforme CinéRoom" }
    role { :admin }
  end
end
