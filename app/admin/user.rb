ActiveAdmin.register User do
  menu priority: 1, label: "Users"

  permit_params :email, :first_name, :last_name, :role, :bio, :password, :password_confirmation

  # Scopes optimisés
  scope :all, default: true
  scope :admin_users, -> { where(role: :admin) }
  scope :regular_users, -> { where(role: :user) }
  scope :creators, -> { where(role: :creator) }
  scope :movie_creators, -> { joins(:movies).distinct }

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

    # Show creator status based on movies created (version corrigée)
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

  # Show page configuration
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

    # Show movies created by this user (if any)
    if user.creator?
      panel "Created Movies" do
        table_for user.movies.limit(10) do
          column :title do |movie|
            link_to movie.title, admin_movie_path(movie)
          end
          column :validation_status do |movie|
            status_tag movie.validation_status.humanize, class: movie.validation_status
          end
          column :year
          column :genre
          column :created_at do |movie|
            movie.created_at.strftime("%d/%m/%Y")
          end
        end
        div do
          link_to "View all movies", admin_movies_path(q: { user_id_eq: user.id })
        end
      end
    end
