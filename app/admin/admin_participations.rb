ActiveAdmin.register Participation do
  menu priority: 5, label: "Participations"

  permit_params :user_id, :event_id, :status, :seats, :stripe_payment_id

  scope :all, default: true
  scope :pending, -> { where(status: :pending) }
  scope :confirmed, -> { where(status: :confirmed) }
  scope :cancelled, -> { where(status: :cancelled) }

  index do
    selectable_column
    id_column

    column :user do |participation|
      link_to participation.user.full_name, admin_user_path(participation.user)
    end

    column :event do |participation|
      link_to participation.event.title, admin_event_path(participation.event)
    end

    column :movie do |participation|
      if participation.event.movie
        link_to participation.event.movie.title, admin_movie_path(participation.event.movie)
      end
    end

    column :event_date do |participation|
      participation.event.event_date
    end

    column :seats

    column :total_price do |participation|
      number_to_currency(participation.event.price_cents * participation.seats / 100.0)
    end

    column :status do |participation|
      status_tag participation.status.humanize, class: participation.status
    end

    column :payment_id do |participation|
      participation.stripe_payment_id.present? ? "✓" : "✗"
    end

    column :created_at do |participation|
      participation.created_at.strftime("%d/%m/%Y")
    end

    actions
  end

  show do
    attributes_table do
      row :id
      row :user do |participation|
        link_to participation.user.full_name, admin_user_path(participation.user)
      end
      row :event do |participation|
        link_to participation.event.title, admin_event_path(participation.event)
      end
      row :movie do |participation|
        if participation.event.movie
          link_to participation.event.movie.title, admin_movie_path(participation.event.movie)
        end
      end
      row :event_date do |participation|
        participation.event.event_date
      end
      row :seats
      row :total_price do |participation|
        number_to_currency(participation.event.price_cents * participation.seats / 100.0)
      end
      row :status do |participation|
        status_tag participation.status.humanize, class: participation.status
      end
      row :stripe_payment_id
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Participation Information" do
      f.input :user, as: :select,
              collection: User.all.map { |u| [ u.full_name, u.id ] },
              prompt: "Select User",
              required: true
      f.input :event, as: :select,
              collection: Event.all.map { |e| [ "#{e.title} - #{e.event_date}", e.id ] },
              prompt: "Select Event",
              required: true
      f.input :seats, required: true, hint: "Number of seats to book"
      f.input :status, as: :select,
              collection: Participation.statuses.map { |key, value| [ key.humanize, key ] },
              include_blank: false
      f.input :stripe_payment_id, hint: "Stripe payment ID if paid"
    end

    f.actions
  end

  batch_action :confirm_participations, confirm: "Confirm selected participations?" do |ids|
    Participation.where(id: ids).update_all(status: :confirmed)
    redirect_to collection_path, notice: "#{ids.count} participations confirmed!"
  end

  batch_action :cancel_participations, confirm: "Cancel selected participations?" do |ids|
    Participation.where(id: ids).update_all(status: :cancelled)
    redirect_to collection_path, notice: "#{ids.count} participations cancelled!"
  end
end
