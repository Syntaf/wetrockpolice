# rubocop:disable Style/FrozenStringLiteralComment
# We don't freeze strings here due to the PayPal SDK modifying string literals

module Area
  class MembershipsController < BaseController
    before_action :verify_order_id, only: %i[create]
    before_action :set_watched_area, only: %i[new]
    before_action :set_meta, only: %i[new]

    def new
      # Disable membership signups
      redirect_to watched_area_path(@watched_area.slug)

      @joint_membership = JointMembershipApplication.new
      @joint_membership.shirt_orders.build
    end

    def create
      @membership = JointMembershipApplication.new(membership_params)
      @membership.pending = true if paid_cash?
      @membership.save!(context: :create)

      unless @membership.pending
        MembershipMailer.with(membership: @membership).signup.deliver_later
        TicketSource::SyncMembershipWorker.perform_async(@membership.id)
      end

      respond_json(
        status: :created,
        modal: render_to_string(
          partial: signup_partial(@membership)
        )
      )
    rescue ActiveRecord::RecordInvalid
      respond_json(
        status: :bad_request,
        errors: @membership.errors
      )
    end

    def validate
      application = JointMembershipApplication.new(membership_params)
      application.prevalidate = true

      unless application.valid?
        respond_json(
          status: :bad_request,
          errors: application.errors
        ) and return
      end

      respond_json(
        status: :ok
      )
    end

    private

    def signup_partial(membership)
      return 'membership_confirmation_modal'.freeze unless membership.pending

      'membership_pending_modal'.freeze
    end

    def verify_order_id
      order_id = params[:joint_membership_application][:order_id]

      return if paid_cash? || PayPalPayments::OrderValidator.call(order_id)

      respond_json(
        status: :payment_required,
        message: 'Invalid order ID Supplied'.freeze
      )
    end

    def paid_cash?
      ActiveRecord::Type::Boolean.new.cast(
        params[:joint_membership_application][:paid_cash]
      )
    end

    def respond_json(content)
      status = content[:status]

      render(
        json: content,
        status: status
      )
    end

    def membership_params
      params.require(:joint_membership_application).permit(
        :first_name,
        :last_name,
        :order_id,
        :organization,
        :amount_paid,
        :email,
        :phone_number,
        :street_line_one,
        :street_line_two,
        :city,
        :state,
        :zipcode,
        :delivery_method,
        :paid_cash,
        :cover_fee,
        shirt_orders_attributes: %i[
          shirt_type
          shirt_size
          shirt_color
        ]
      )
    end

    def set_meta
      @page_title = 'Support local coalitions'
      @page_description = <<~TEXT
        Signup for a membership today with your local coalition and help make
        a difference in the climbing community. Foster service projects and
        maintain access to our climbing areas through coalition memberships
      TEXT
    end
  end
end

# rubocop:enable Style/FrozenStringLiteralComment
