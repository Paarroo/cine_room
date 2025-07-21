ActiveAdmin.register Movie do
  menu priority: 4, label: "Movies"

  permit_params :user_id, :title, :synopsis, :director, :duration, :genre, :language,
                :year, :trailer_url, :poster_url, :validation_status

  config.filters = false

  scope :all, default: true
  scope :pending, -> { where(validation_status: :pending) }
  scope :approved, -> { where(validation_status: :approved) }
  scope :rejected, -> { where(validation_status: :rejected) }

  # Custom search without Ransack
  controller do
    def scoped_collection
      super.includes(:user, :validated_by, :events)
    end

    def index
      # Custom filtering logic without Ransack
      @movies = scoped_collection

      # Apply scope if present
      if params[:scope].present? && %w[pending approved rejected].include?(params[:scope])
        @movies = @movies.where(validation_status: params[:scope])
      end

      # Simple search by title if q parameter present
      if params[:q].present? && params[:q][:title_cont].present?
        @movies = @movies.where("title ILIKE ?", "%#{params[:q][:title_cont]}%")
      end

      # Apply ordering
      @movies = @movies.order(created_at: :desc)

      # Paginate results
      @movies = @movies.page(params[:page]).per(25)

      @collection = @movies
    end
  end

  # Custom search form without Ransack dependency
  content title: "Movies" do
    div class: "custom-search-form" do
      form action: admin_movies_path, method: "get" do
        div style: "display: flex; gap: 10px; margin-bottom: 20px; align-items: end;" do
          div do
            label "Search by title:", for: "search_title"
            text_field_tag "q[title_cont]", params.dig(:q, :title_cont),
                          placeholder: "Movie title...",
                          id: "search_title",
                          style: "padding: 8px; border: 1px solid #ccc; border-radius: 4px;"
          end

          div do
            label "Status:", for: "search_status"
            select_tag "scope",
                      options_for_select([
                        [ 'All', '' ],
                        [ 'Pending', 'pending' ],
                        [ 'Approved', 'approved' ],
                        [ 'Rejected', 'rejected' ]
                      ], params[:scope]),
                      id: "search_status",
                      style: "padding: 8px; border: 1px solid #ccc; border-radius: 4px;"
          end

          submit_tag "Search",
                    style: "padding: 8px 16px; background: #007cba; color: white; border: none; border-radius: 4px; cursor: pointer;"

          link_to "Clear", admin_movies_path,
                 style: "padding: 8px 16px; background: #666; color: white; text-decoration: none; border-radius: 4px; margin-left: 5px;"
        end
      end
    end
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

    actions
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

  # Batch actions for movies
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

  # Custom actions for individual movies
  member_action :approve, method: :patch do
    resource.update!(
      validation_status: :approved,
      validated_by: current_user,
      validated_at: Time.current
    )
    redirect_to admin_movie_path(resource), notice: "Movie approved!"
  end

  member_action :reject, method: :patch do
    resource.update!(
      validation_status: :rejected,
      validated_by: current_user,
      validated_at: Time.current
    )
    redirect_to admin_movie_path(resource), notice: "Movie rejected!"
  end

  action_item :approve, only: :show, if: proc { resource.pending? } do
    link_to "Approve Movie", approve_admin_movie_path(resource), method: :patch,
            class: "button", confirm: "Are you sure you want to approve this movie?"
  end

  action_item :reject, only: :show, if: proc { resource.pending? } do
    link_to "Reject Movie", reject_admin_movie_path(resource), method: :patch,
            class: "button", confirm: "Are you sure you want to reject this movie?"
  end
end
