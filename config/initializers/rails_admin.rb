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

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end
