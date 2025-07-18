ActiveAdmin.register Participation do
  menu priority: 5, label: "Participations"

  permit_params :user_id, :event_id, :status, :seats, :stripe_payment_id

  scope :all, default: true
  scope :pending, -> { where(status: :pending) }
  scope :confirmed, -> { where(status: :confirmed) }
  scope :cancelled, -> { where(status: :cancelled) }

  filter :user, as: :select, collection: -> { User.all.map { |u| [u.full_name, u.id] } }
  filter :event, as: :select, collection: -> { Event.all.map { |e| [e.title, e.id] } }
  filter :status, as: :select, collection: Participation.statuses.map { |key, value| [ key.humanize, key ] }
  filter :seats
  filter :created_at

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
