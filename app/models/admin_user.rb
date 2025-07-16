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

    panel "Participations" do
      table_for user.participations.includes(:event) do
        column :event do |participation|
          link_to participation.event.title, admin_event_path(participation.event)
        end
        column :status do |participation|
          status_tag participation.status.humanize
        end
        column :seats
        column :created_at
      end
    end

    panel "Reviews" do
      table_for user.reviews.includes(:movie, :event) do
        column :movie do |review|
          link_to review.movie.title, admin_movie_path(review.movie)
        end
        column :event do |review|
          link_to review.event.title, admin_event_path(review.event)
        end
        column :rating do |review|
          "⭐" * review.rating if review.rating
        end
        column :comment do |review|
          truncate(review.comment, length: 50) if review.comment
        end
      end
    end
  end

  form do |f|
    f.inputs "User Details" do
      f.input :email
      f.input :first_name
      f.input :last_name
      f.input :role, as: :select, collection: User.roles
      f.input :bio, as: :text
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end
