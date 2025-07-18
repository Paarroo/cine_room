ActiveAdmin.register User do
  menu priority: 1, label: "Users"

  permit_params :email, :first_name, :last_name, :role, :bio, :password, :password_confirmation

  scope :all, default: true
  scope :admins, -> { where(role: :admin) }
  scope :users, -> { where(role: :user) }
  scope :creators, -> { creators }

  # Filters for search functionality
  filter :email
  filter :first_name
  filter :last_name
  filter :role, as: :select, collection: User.roles.map { |key, value| [ key.humanize, key ] }
  filter :created_at
  filter :updated_at

  # Index page configuration
  index do
    selectable_column
    id_column

    column :email do |user|
      link_to user.email, admin_user_path(user)
    end

    column :full_name do |user|
      user.full_name
    end

    column :role do |user|
      status_tag user.role.humanize, class: user.role
    end

    # Show creator status based on movies created
    column :creator_status do |user|
      if user.creator?
        status_tag "Creator", class: "yes"
      else
        status_tag "Not a creator", class: "no"
      end
    end

    column :movies_count do |user|
      user.movies.count
    end

    column :participations_count do |user|
      user.participations.count
    end

    column :created_at do |user|
      user.created_at.strftime("%d/%m/%Y")
    end

    actions
  end
