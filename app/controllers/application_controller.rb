# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def after_sign_in_path_for(_resource)
    rails_admin_path
  end

  private

  def render404
    render file: 'public/404.html', layout: false, status: :not_found
  end
end
