require 'rails_admin/mark_delivered_action'

RailsAdmin.config do |config|  
  ### Popular gems integration
  config.main_app_name = Proc.new{|controller| [ 'Wetrockpolice', "Admin - #{controller.params[:action].try(:titleize)}"]}

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  ## == Cancan ==
  config.authorize_with :cancancan
  config.parent_controller = 'ApplicationController'

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.model ClimbingArea do
    edit do
      configure :rainy_day_areas do
        hide
      end

      configure :watched_areas do
        inline_add false
      end
    end
  end

  config.model Location do
    edit do
      configure :rainy_day_areas do
        hide
      end
    end
  end

  config.model JointMembershipApplication do
    include_fields :delivered, :created_at, :first_name, :last_name, :amount_paid, :order_id,
      :email, :phone_number, :street_line_one, :street_line_two, :city, :state,
      :zipcode, :organization, :delivery_method, :delivered, :shirt_orders
  end

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    mark_delivered do
      only ['JointMembershipApplication']
    end

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end
