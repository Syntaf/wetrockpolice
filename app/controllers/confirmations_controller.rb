# frozen_string_literal: true

class ConfirmationsController < Devise::ConfirmationsController
    private
    def after_confirmation_path_for(resource_name, resource)
      sign_in(resource)
      
      if current_user.admin?
        redirect_to rails_admin
      end
    end
  end