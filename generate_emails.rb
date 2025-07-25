# Generate email previews for CinéRoom
puts "🎬 Generating email previews for CinéRoom..."

# Clear existing test users
User.where(email: ["test@example.com", "reset@example.com", "change@example.com", "emailchange@example.com", "locked@example.com"]).delete_all

# 1. Confirmation Instructions
user = User.create!(email: "test@example.com", password: "password123", first_name: "Test", last_name: "User")
user.send_confirmation_instructions
puts "✅ Confirmation email sent"

# 2. Reset Password Instructions  
existing_user = User.create!(email: "reset@example.com", password: "password123", first_name: "Reset", last_name: "User", confirmed_at: Time.current)
existing_user.send_reset_password_instructions  
puts "✅ Reset password email sent"

# 3. Password Change Notification
confirmed_user = User.create!(email: "change@example.com", password: "password123", first_name: "Change", last_name: "User", confirmed_at: Time.current)
Devise::Mailer.password_change(confirmed_user, {}).deliver_now
puts "✅ Password change email sent"

# 4. Email Changed Notification
email_user = User.create!(email: "emailchange@example.com", password: "password123", first_name: "Email", last_name: "User", confirmed_at: Time.current)
Devise::Mailer.email_changed(email_user, {}).deliver_now
puts "✅ Email changed notification sent"

# 5. Unlock Instructions
locked_user = User.create!(email: "locked@example.com", password: "password123", first_name: "Locked", last_name: "User", confirmed_at: Time.current)
locked_user.lock_access!
locked_user.send_unlock_instructions
puts "✅ Unlock instructions sent"

puts "🎉 All email previews generated! Check your browser with Letter Opener."