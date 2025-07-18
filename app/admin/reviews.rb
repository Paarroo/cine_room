ActiveAdmin.register Review do
  menu priority: 6, label: "Reviews"

  permit_params :user_id, :movie_id, :event_id, :rating, :comment

  scope :all, default: true
  scope :with_rating, -> { where.not(rating: nil) }
  scope :with_comment, -> { where.not(comment: [ nil, "" ]) }
  scope :recent, -> { where("created_at > ?", 1.month.ago) }

  filter :user, as: :select, collection: -> { User.all.map { |u| [ u.full_name, u.id ] } }
  filter :movie, as: :select, collection: -> { Movie.all.map { |m| [ m.title, m.id ] } }
  filter :event, as: :select, collection: -> { Event.all.map { |e| [ e.title, e.id ] } }
  filter :rating, as: :select, collection: (1..5).to_a
  filter :created_at

  index do
    selectable_column
    id_column

    column :user do |review|
      link_to review.user.full_name, admin_user_path(review.user)
    end

    column :movie do |review|
      link_to review.movie.title, admin_movie_path(review.movie)
    end

    column :event do |review|
      link_to review.event.title, admin_event_path(review.event)
    end

    column :rating do |review|
      if review.rating
        content_tag :span, "⭐" * review.rating, title: "#{review.rating}/5 stars"
      else
        "-"
      end
    end
