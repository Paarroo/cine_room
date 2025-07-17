test_user = User.create!(
  email: 'test@cineroom.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Jean',
  last_name: 'Cinéphile',
  role: :user
)

admin_user = User.create!(
  email: 'admin@cineroom.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Admin',
  last_name: 'CinéRoom',
  role: :admin
)
