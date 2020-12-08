# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :reload_rails_admin, if: :rails_admin_path?

  def after_sign_in_path_for(_resource)
    rails_admin_path
  end

  private

  def render404
    render file: 'public/404.html', layout: false, status: :not_found
  end

  def reload_rails_admin
    models = %w[
      ClimbingArea
      JointMembershipApplication
      LocalClimbingOrg
      Location
      RainyDayArea
      ShirtOrder
      User
      WatchedArea
    ]

    models.each do |m|
      RailsAdmin::Config.reset_model(m)
    end
    RailsAdmin::Config::Actions.reset

    load(Rails.root.join('config/initializers/rails_admin.rb'))
    load(Rails.root.join('lib/rails_admin/mark_delivered_action.rb'))
  end

  def rails_admin_path?
    controller_path =~ /rails_admin/ && Rails.env.development?
  end
end
