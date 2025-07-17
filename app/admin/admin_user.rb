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
  filter :role, as: :select, collection: User.roles.map { |key, value| [ key.humanize, key ] }
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

    if user.creator.present?
      panel "Creator Information" do
        attributes_table_for user.creator do
          row :status do |creator|
            status_tag creator.status.humanize, class: creator.status
          end
          row :bio
          row :verified_at
          row :created_at
        end
      end

      panel "Creator's Movies" do
        table_for user.creator.movies.limit(10) do
          column :title do |movie|
            link_to movie.title, admin_movie_path(movie)
          end
          column :validation_status do |movie|
            status_tag movie.validation_status.humanize, class: movie.validation_status
          end
          column :year
          column :genre
        end
        div do
          link_to "View all movies", admin_movies_path(q: { creator_id_eq: user.creator.id })
        end
      end
    end

    panel "Participations" do
      table_for user.participations.includes(:event).limit(10) do
        column :event do |participation|
          link_to participation.event.title, admin_event_path(participation.event)
        end
        column :status do |participation|
          status_tag participation.status.humanize, class: participation.status
        end
        column :seats
        column :created_at do |participation|
          participation.created_at.strftime("%d/%m/%Y")
        end
      end
      div do
        link_to "View all participations", admin_participations_path(q: { user_id_eq: user.id })
      end
    end
    panel "Reviews" do
          table_for user.reviews.includes(:movie, :event).limit(10) do
            column :movie do |review|
              link_to review.movie.title, admin_movie_path(review.movie)
            end
            column :event do |review|
              link_to review.event.title, admin_event_path(review.event)
            end
            column :rating do |review|
              "⭐" * review.rating if review.rating
            end
            column :created_at do |review|
              review.created_at.strftime("%d/%m/%Y")
            end
          end
          div do
            link_to "View all reviews", admin_reviews_path(q: { user_id_eq: user.id })
          end
        end
      end

  form do |f|
      f.semantic_errors

      f.inputs "User Information" do
        f.input :email, required: true
        f.input :first_name
        f.input :last_name
        f.input :role, as: :select, collection: User.roles.map { |key, value| [key.humanize, key] }, include_blank: false
        f.input :bio, as: :text, input_html: { rows: 4 }
      end

      f.inputs "Password" do
        f.input :password, hint: "Leave blank to keep current password"
        f.input :password_confirmation
      end

      f.actions
    end

    # Batch actions
    batch_action :promote_to_admin, confirm: "Are you sure you want to promote selected users to admin?" do |ids|
      User.where(id: ids).update_all(role: :admin)
      redirect_to collection_path, notice: "Users promoted to admin successfully!"
    end

    batch_action :demote_to_user, confirm: "Are you sure you want to demote selected users?" do |ids|
      User.where(id: ids).update_all(role: :user)
      redirect_to collection_path, notice: "Users demoted successfully!"
    end

    # Custom actions
    member_action :reset_password, method: :put do
      user = User.find(params[:id])
      new_password = SecureRandom.hex(8)
      user.update!(password: new_password, password_confirmation: new_password)

      # Here send an email with the new password
      # UserMailer.password_reset(user, new_password).deliver_now

      redirect_to resource_path, notice: "Password reset successfully! New password: #{new_password}"
    end

    action_item :reset_password, only: :show do
      link_to "Reset Password", reset_password_admin_user_path(user), method: :put,
              confirm: "Are you sure? This will generate a new password.",
              class: "button"
    end
    csv do
        column :id
        column :email
        column :first_name
        column :last_name
        column :role
        column("Full Name") { |user| "#{user.first_name} #{user.last_name}".strip }
        column("Participations Count") { |user| user.participations.count }
        column("Is Creator") { |user| user.creator.present? ? "Yes" : "No" }
        column :created_at
      end

      # Controller customization
      controller do
        def create
          @user = User.new(permitted_params[:user])

          if @user.save
            redirect_to admin_user_path(@user), notice: "User created successfully!"
          else
            render :new
          end
        end

        def update
          # Don't require current password for admin updates
          user_params = permitted_params[:user]

          if user_params[:password].blank?
            user_params.delete(:password)
            user_params.delete(:password_confirmation)
          end

          if resource.update(user_params)
            redirect_to admin_user_path(resource), notice: "User updated successfully!"
          else
            render :edit
          end
        end
      end
    end
  end
end
