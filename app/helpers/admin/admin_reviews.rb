ActiveAdmin.register Review do
  menu priority: 6, label: "Reviews"

  permit_params :user_id, :movie_id, :event_id, :rating, :comment

  scope :all, default: true
  scope :with_rating, -> { where.not(rating: nil) }
  scope :with_comment, -> { where.not(comment: [ nil, "" ]) }
  scope :recent, -> { where("created_at > ?", 1.month.ago) }

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

    column :comment do |review|
      if review.comment.present?
        truncate(review.comment, length: 80)
      else
        content_tag :span, "No comment", class: "empty"
      end
    end

    column :event_date do |review|
      review.event.event_date
    end

    column :created_at do |review|
      review.created_at.strftime("%d/%m/%Y")
    end

    actions
  end

  show do
    attributes_table do
      row :id
      row :user do |review|
        link_to review.user.full_name, admin_user_path(review.user)
      end
      row :movie do |review|
        link_to review.movie.title, admin_movie_path(review.movie)
      end
      row :event do |review|
        link_to review.event.title, admin_event_path(review.event)
      end
      row :rating do |review|
        if review.rating
          content_tag :span, "⭐" * review.rating + " (#{review.rating}/5)",
                      style: "font-size: 1.2em;"
        else
          "No rating given"
        end
      end
      row :comment do |review|
        if review.comment.present?
          simple_format(review.comment)
        else
          content_tag :span, "No comment provided", class: "empty"
        end
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Review Information" do
      f.input :user, as: :select,
              collection: User.all.map { |u| [ u.full_name, u.id ] },
              prompt: "Select User",
              required: true
      f.input :movie, as: :select,
              collection: Movie.where(validation_status: :validated).map { |m| [ m.title, m.id ] },
              prompt: "Select Movie",
              required: true
      f.input :event, as: :select,
              collection: Event.all.map { |e| [ "#{e.title} - #{e.event_date}", e.id ] },
              prompt: "Select Event",
              required: true,
              hint: "Event must match the selected movie"
      f.input :rating, as: :select,
              collection: (1..5).map { |r| [ r, r ] },
              prompt: "Select Rating (1-5 stars)",
              hint: "1 = Poor, 5 = Excellent"
      f.input :comment, as: :text,
              input_html: { rows: 6 },
              hint: "Optional comment about the movie/event"
    end

    f.actions
  end
end
