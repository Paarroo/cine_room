ActiveAdmin.register User do
  menu priority: 1, label: "Users"

  permit_params :email, :first_name, :last_name, :role, :bio, :password, :password_confirmation

  scope :all, default: true
  scope :admins, -> { where(role: :admin) }
  scope :users, -> { where(role: :user) }
  scope :creators, -> { joins(:creator) }

  filter :email
  filter :first_name
  filter :last_name
  filter :role, as: :select, collection: User.roles.map { |key, value| [key.humanize, key] }
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column

    column :email do |user|
      link_to user.email, admin_user_path(user)
    end

    column :full_name do |user|
      "#{user.first_name} #{user.last_name}".strip
    end

    column :role do |user|
      status_tag user.role.humanize, class: user.role
    end

    column :creator_status do |user|
      if user.creator.present?
        status_tag user.creator.status.humanize, class: user.creator.status
      else
        status_tag "Not a creator", class: "no"
      end
    end

    column :participations_count do |user|
      user.participations.count
    end

    column :created_at do |user|
      user.created_at.strftime("%d/%m/%Y")
    end

    actions
  end
  show do
      attributes_table do
        row :id
        row :email
        row :first_name
        row :last_name
        row :role do |user|
          status_tag user.role.humanize, class: user.role
        end
        row :bio
        row :created_at
        row :updated_at
        row :last_sign_in_at if user.respond_to?(:last_sign_in_at)
      end

  end
