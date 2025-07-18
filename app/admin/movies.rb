ActiveAdmin.register Movie do
  menu priority: 4, label: "Movies"

  permit_params :user_id, :title, :synopsis, :director, :duration, :genre, :language,
                :year, :trailer_url, :poster_url, :validation_status

  scope :all, default: true
  scope :pending, -> { where(validation_status: :pending) }
  scope :validated, -> { where(validation_status: :validated) }
  scope :rejected, -> { where(validation_status: :rejected) }

  filter :title
  filter :director
  filter :genre
  filter :year
  filter :language
  filter :validation_status, as: :select, collection: Movie.validation_statuses.map { |key, value| [ key.humanize, key ] }
  filter :user, as: :select, collection: -> { User.joins(:movies).distinct.map { |u| [u.full_name, u.id] } }
  filter :created_at

  index do
    selectable_column
    id_column

    column :title do |movie|
      link_to movie.title, admin_movie_path(movie)
    end

    column :creator do |movie|
      link_to movie.user.full_name, admin_user_path(movie.user) if movie.user
    end

    column :director
    column :year
    column :genre

    column :validation_status do |movie|
      status_tag movie.validation_status.humanize, class: movie.validation_status
    end

    column :validated_by do |movie|
      if movie.validated_by
        link_to movie.validated_by.full_name, admin_user_path(movie.validated_by)
      else
        "-"
      end
    end
