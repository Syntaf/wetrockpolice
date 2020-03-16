# frozen_string_literal: true

module Area
  class MembershipsController < BaseController
    before_action :verify_order_id, only: %i[create]

    def new
      @joint_membership = JointMembershipApplication.new
    end

    def create
      @membership = JointMembershipApplication.new(membership_params)
      @membership.pending = true if paid_cash?

      @membership.save!(context: :create)

      unless @membership.pending
        MembershipMailer.with(membership: @membership).signup.deliver_later
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
          errors: membership.errors
        )
      end

      respond_json(
        status: :ok
      )
    end

    private

    def signup_partial(membership)
      return 'membership_confirmation_modal.html.erb' unless membership.pending

      'membership_pending_modal.html.erb'
    end

    def verify_order_id
      order_id = params[:joint_membership_application][:order_id]

      return if paid_cash? || PayPalPayments::OrderValidator.call(order_id)

      respond_json(
        status: :payment_required,
        message: 'Invalid order ID Supplied'
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
        :local_shirt,
        :access_fund_shirt,
        :shirt_size,
        :paid_cash
      )
    end
  end
end
