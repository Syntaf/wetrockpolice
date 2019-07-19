class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # rescue_from CanCan::AccessDenied do |exception|
  #   respond_to do |format|
  #     format.json { render nothing: true, status: :forbidden }
  #     format.xml { render xml: '...', status: :forbidden }
  #     format.html { redirect_to main_app.root_path, alert: exception.message }
  #   end
  # end

  def after_sign_in_path_for(resource)
    admin_path
  end
end
