ActiveAdmin.register User do
  permit_params :email, :first_name, :last_name, :role, :bio, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column :first_name
    column :last_name
    column :role do |user|
      status_tag user.role.humanize, class: user.admin? ? 'error' : 'ok'
    end
    column :participations_count do |user|
      user.participations.count
    end
    column :created_at
    actions
  end

  filter :email
  filter :first_name
  filter :last_name
  filter :role, as: :select, collection: User.roles
  filter :created_at

  show do
    attributes_table do
      row :id
      row :email
      row :first_name
      row :last_name
      row :role do |user|
        status_tag user.role.humanize, class: user.admin? ? 'error' : 'ok'
      end
      row :bio
      row :created_at
      row :updated_at
    end
