# frozen_string_literal: true

class ConfirmationsController < Devise::ConfirmationsController
  private

  def after_confirmation_path_for(_resource_name, resource)
    sign_in(resource)

    redirect_to rails_admin if current_user.admin?
  end
end
