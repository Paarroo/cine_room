ActiveAdmin.register Movie do
  menu priority: 4, label: "Movies"

  permit_params :user_id, :title, :synopsis, :director, :duration, :genre, :language,
                :year, :trailer_url, :poster_url, :validation_status

  scope :all, default: true
  scope :pending, -> { where(validation_status: :pending) }
  scope :approved, -> { where(validation_status: :approved) }
  scope :rejected, -> { where(validation_status: :rejected) }

  # CUSTOM MEMBER ACTIONS FOR DASHBOARD
  member_action :validate_movie, method: :patch do
    resource.update!(
      validation_status: :approved,
      validated_by: current_user,
      validated_at: Time.current
    )
    redirect_to "/admin", notice: "Film validé avec succès !"
  end

  member_action :reject_movie, method: :patch do
    resource.update!(
      validation_status: :rejected,
      validated_by: current_user,
      validated_at: Time.current
    )
    redirect_to "/admin", notice: "Film rejeté."
  end

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

    column :events_count do |movie|
      movie.events.count
    end

    column :created_at do |movie|
      movie.created_at.strftime("%d/%m/%Y")
    end

    actions do |movie|
      if movie.pending?
        item "Valider", validate_movie_admin_movie_path(movie), method: :patch,
             class: "button", confirm: "Valider ce film ?"
        item "Rejeter", reject_movie_admin_movie_path(movie), method: :patch,
             class: "button", confirm: "Rejeter ce film ?"
      end
    end
  end

  show do
    attributes_table do
      row :title
      row :synopsis do |movie|
        simple_format(movie.synopsis)
      end
      row :creator do |movie|
        link_to movie.user.full_name, admin_user_path(movie.user) if movie.user
      end
      row :director
      row :duration do |movie|
        "#{movie.duration} minutes"
      end
      row :genre
      row :language
      row :year
      row :validation_status do |movie|
        status_tag movie.validation_status.humanize, class: movie.validation_status
      end
      row :validated_by do |movie|
        if movie.validated_by
          link_to movie.validated_by.full_name, admin_user_path(movie.validated_by)
        end
      end
      row :validated_at
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Movie Information" do
      f.input :user, as: :select,
              collection: User.order(:first_name).map { |u| [ u.full_name, u.id ] },
              prompt: "Select Creator",
              required: true
      f.input :title, required: true
      f.input :synopsis, as: :text, input_html: { rows: 6 }, required: true
      f.input :director, required: true
      f.input :duration, hint: "Duration in minutes", required: true
      f.input :genre, required: true
      f.input :language, as: :select,
              collection: [ [ 'French', 'fr' ], [ 'English', 'en' ], [ 'Spanish', 'es' ], [ 'Other', 'other' ] ],
              include_blank: false
      f.input :year, required: true
      f.input :trailer_url, hint: "YouTube or Vimeo URL"
      f.input :poster_url, hint: "Direct image URL"
    end

    f.inputs "Validation" do
      f.input :validation_status, as: :select,
              collection: Movie.validation_statuses.map { |key, value| [ key.humanize, key ] },
              include_blank: false
    end

    f.actions
  end

  # Batch actions
  batch_action :approve_movies, confirm: "Approve selected movies?" do |ids|
    Movie.where(id: ids).update_all(
      validation_status: :approved,
      validated_by_id: current_user.id,
      validated_at: Time.current
    )
    redirect_to collection_path, notice: "#{ids.count} movies approved successfully!"
  end

  batch_action :reject_movies, confirm: "Reject selected movies?" do |ids|
    Movie.where(id: ids).update_all(
      validation_status: :rejected,
      validated_by_id: current_user.id,
      validated_at: Time.current
    )
    redirect_to collection_path, notice: "#{ids.count} movies rejected!"
  end

  action_item :approve, only: :show, if: proc { resource.pending? } do
    link_to "Approve Movie", validate_movie_admin_movie_path(resource), method: :patch,
            class: "button", confirm: "Are you sure you want to approve this movie?"
  end

  action_item :reject, only: :show, if: proc { resource.pending? } do
    link_to "Reject Movie", reject_movie_admin_movie_path(resource), method: :patch,
            class: "button", confirm: "Are you sure you want to reject this movie?"
  end
end
