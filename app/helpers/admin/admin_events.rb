ActiveAdmin.register Event do
  menu priority: 3, label: "Events"

  permit_params :title, :description, :venue_name, :venue_address, :event_date,
                :start_time, :max_capacity, :price_cents, :status, :latitude, :longitude

  scope :all, default: true
  scope :upcoming, -> { where(status: :upcoming) }
  scope :completed, -> { where(status: :completed) }
  scope :sold_out, -> { where(status: :sold_out) }

  index do
    selectable_column
    id_column

    column :title do |event|
      link_to event.title, admin_event_path(event)
    end

    column :movie do |event|
      event.movie.title if event.movie
    end

    column :venue_name
    column :event_date
    column :max_capacity

    column :price do |event|
      number_to_currency(event.price_cents / 100.0)
    end

    column :status do |event|
      status_tag event.status.humanize, class: event.status
    end

    actions
  end

  show do
    attributes_table do
      row :title
      row :description
      row :movie
      row :venue_name
      row :venue_address
      row :event_date
      row :start_time
      row :max_capacity
      row :price do |event|
        number_to_currency(event.price_cents / 100.0)
      end
      row :status do |event|
        status_tag event.status.humanize, class: event.status
      end
      row :created_at
      row :updated_at
    end
  end
end
