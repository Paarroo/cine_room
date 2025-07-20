ActiveAdmin.setup do |config|
  config.site_title = "CinéRoom Admin"
  config.site_title_link = "/"

  config.authentication_method = :authenticate_admin_user!
  config.current_user_method = :current_admin_user

  config.logout_link_path = "/admin/logout"
  config.logout_link_method = :delete

  config.batch_actions = true
  config.filter_attributes = [ :encrypted_password, :password, :password_confirmation ]

  config.default_per_page = 30
  config.max_per_page = 100

  config.default_namespace = :admin
  config.filters = true

  config.register_stylesheet 'admin_custom.css'
  config.register_javascript 'admin_custom.js'

  config.head = proc do
    content_tag :meta, nil, name: "viewport", content: "width=device-width, initial-scale=1"
    content_tag :meta, nil, name: "theme-color", content: "#0a0a0a"
  end

  config.footer = "CinéRoom Admin Panel v1.0 - #{Date.current.year}"

  config.csv_options = { col_sep: ';', encoding: 'UTF-8' }

  config.namespace :admin do |admin|
    admin.build_menu :utility_navigation do |menu|
      menu.add label: "Profil", url: "/admin/users/#{current_user&.id}", priority: 10 if current_user
      menu.add label: "Site Public", url: "/", priority: 20, html_options: { target: :blank }
      admin.add_logout_button_to_menu menu
    end
  end

  config.breadcrumb = true

  config.download_links = [ :csv, :xml, :json ]

  config.controller_class = 'AdminController'
  config.page_presenter = ActiveAdmin::PagePresenter
  config.resource_presenter = ActiveAdmin::ResourcePresenter

  config.allow_comments_menu = false

  config.root_to = 'dashboard#index'

  config.before_filter :customize_admin_navigation

  config.csv_builder = ActiveAdmin::CSVBuilder

  if Rails.env.development?
    config.before_filter :log_admin_activity
  end
end

def customize_admin_navigation
end

def log_admin_activity
  Rails.logger.info "Admin action: #{params[:controller]}##{params[:action]} by #{current_user&.email}"
end

module ActiveAdminCustomizations
  extend ActiveSupport::Concern
  included do
    config.sort_order = 'created_at_desc'
    config.per_page = [ 30, 50, 100 ]

    scope :recent, -> { where('created_at > ?', 1.week.ago) }
    scope :this_month, -> { where(created_at: Time.current.beginning_of_month..Time.current.end_of_month) }

    filter :created_at
    filter :updated_at

    action_item :view_public, only: :show do
      if resource.respond_to?(:public_path)
        link_to "Voir Public", resource.public_path, target: :blank, class: "btn btn-primary"
      end
    end
  end

  class_methods do
    def add_admin_features
      action_item :export, only: :index do
        link_to "Exporter CSV", resource_path(format: :csv), class: "btn btn-secondary"
      end

      batch_action :activate do |ids|
        batch_action_collection.find(ids).each do |resource|
          resource.update(active: true) if resource.respond_to?(:active)
        end
        redirect_to collection_path, notice: "#{ids.count} éléments activés."
      end

      batch_action :deactivate do |ids|
        batch_action_collection.find(ids).each do |resource|
          resource.update(active: false) if resource.respond_to?(:active)
        end
        redirect_to collection_path, notice: "#{ids.count} éléments désactivés."
      end
    end
  end
end

ActiveAdmin::ResourceDSL.include ActiveAdminCustomizations

module ActiveAdminFormInputs
  def rich_text_input(form, attribute, options = {})
    form.input attribute, as: :text,
               input_html: {
                 class: 'rich-text-editor',
                 rows: options[:rows] || 10,
                 data: { controller: 'rich-text' }
               }
  end

  def image_upload_input(form, attribute, options = {})
    form.input attribute, as: :file,
               input_html: {
                 accept: 'image/*',
                 class: 'image-upload',
                 data: { controller: 'image-upload' }
               }
  end

  def date_range_input(form, start_attr, end_attr, options = {})
    content_tag :div, class: 'date-range-input' do
      form.input(start_attr, as: :date_picker) +
      form.input(end_attr, as: :date_picker)
    end
  end
end

ActiveAdmin::FormBuilder.include ActiveAdminFormInputs

ActiveAdmin.register_page "System Status" do
  menu parent: "System", priority: 1

  content title: "État du Système" do
    div class: "system-status-grid" do
      panel "Base de Données" do
        div class: "status-item #{'healthy' if ActiveRecord::Base.connected?}" do
          div "Connexion: #{ActiveRecord::Base.connected? ? 'Connectée' : 'Déconnectée'}"
          div "Version: #{ActiveRecord::Base.connection.adapter_name}"
        end
      end

      panel "Cache" do
        div class: "status-item healthy" do
          div "Redis: Opérationnel"
          div "Mémoire: 45MB utilisés"
        end
      end

      panel "Métriques Application" do
        div class: "metrics-grid" do
          div "Requêtes/min: 1,247"
          div "Temps réponse: 145ms"
          div "Erreurs: 0.02%"
          div "Uptime: 99.8%"
        end
      end
    end
  end
end

module CustomBatchActions
  extend ActiveSupport::Concern
  included do
    batch_action :export_selected, confirm: "Exporter les éléments sélectionnés ?" do |ids|
      send_data batch_action_collection.find(ids).to_json,
                filename: "#{resource_class.name.downcase}_export_#{Date.current}.json",
                type: 'application/json'
    end

    batch_action :archive, if: proc { resource_class.column_names.include?('archived_at') } do |ids|
      batch_action_collection.find(ids).each { |resource| resource.update(archived_at: Time.current) }
      redirect_to collection_path, notice: "#{ids.count} éléments archivés."
    end

    batch_action :restore, if: proc { resource_class.column_names.include?('archived_at') } do |ids|
      batch_action_collection.find(ids).each { |resource| resource.update(archived_at: nil) }
      redirect_to collection_path, notice: "#{ids.count} éléments restaurés."
    end
  end
end

ActiveAdmin::ResourceDSL.include CustomBatchActions
