# frozen_string_literal: true

class MembershipsController < ApplicationController
  before_action :verify_order_id, only: %i[create]
  before_action :authenticate_user!, only: %i[confirm_cash_payments]

  def new
    @watched_area = WatchedArea.find_by(id: params[:watched_area_id])
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

    respond_to do |format|
      format.json { render json: { status: :valid } } if application.valid?

      format.json do
        render json: {
          status: :bad_request,
          errors: application.errors
        }, status: 400
      end
    end
  end

  def pending_cash_payments
    @pending_memberships = JointMembershipApplication.where(pending: true).order(:first_name)
  end

  def confirm_cash_payments
    pending_membership = JointMembershipApplication.find(params[:id])
    pending_membership.pending = false

    respond_to do |format|
      if pending_membership.save
        MembershipMailer.with(application: pending_membership).signup_confirmation.deliver_later

        format.json { render json: {status: :updated } }
      end

      format.json { render json: { status: :unhandled_error, errors: pending_membership.errors } }
    end
  end

  def deny_cash_payments
    pending_membership = JointMembershipApplication.find(params[:id])

    respond_to do |format|
      if pending_membership.delete
        format.json { render json: {status: :updated } }
      end

      format.json { render json: { status: :unhandled_error, errors: pending_membership.errors } }
    end
  end

  private

  def signup_partial(membership)
    'membership_confirmation_modal.html.erb' if membership.pending
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
