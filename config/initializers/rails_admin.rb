RailsAdmin.config do |config|  
  ### Popular gems integration
  config.main_app_name = Proc.new{|controller| [ 'Wetrockpolice', "Admin - #{controller.params[:action].try(:titleize)}"]}
  config.asset_source = :importmap

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

  # Devise 5 declares the password length validator with procs
  # (`maximum: proc { password_length.max }`), and rails_admin 3.3's generated
  # field help does `[length, valid_length[:maximum]].min`, which raises
  # "comparison of Integer with Proc failed" — the User new/edit forms 500.
  # Explicit help text skips that computation.
  config.model User do
    configure :password do
      help { "#{required? ? 'Required' : 'Optional'}. Length of #{Devise.password_length.min}-#{Devise.password_length.max}." }
    end
  end

  config.model Location do
    edit do
      configure :rainy_day_areas do
        hide
      end
    end
  end

  # Partner API keys are created with `bin/rails "api_keys:create[Name]"`,
  # which prints the key once; here they can only be renamed or revoked.
  config.model ApiKey do
    list do
      field :name
      field :active
      field :last_used_at
      field :created_at
    end
    edit do
      field :name
      field :active do
        help 'Untick to revoke this key.'
      end
    end
  end

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new do
      except ['ApiKey']
    end
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
