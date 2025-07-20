class Admin::BaseController < ApplicationController
  before_action :ensure_admin!
  before_action :set_admin_layout
  before_action :add_admin_breadcrumbs

  private

  def set_admin_layout
    self.class.layout 'admin_custom'
  end

  def add_admin_breadcrumbs
    add_breadcrumb('Dashboard', admin_root_path)
  end
end
