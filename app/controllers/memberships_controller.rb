# frozen_string_literal: true

class MembershipsController < ApplicationController
  respond_to
  before_action :authenticate_user!, only: %i[confirm_cash_payments]

  def new
    @watched_area = WatchedArea.find_by(id: params[:watched_area_id])
    @joint_membership = JointMembershipApplication.new
  end

  def create
    order_id = params[:joint_membership_application][:order_id]
    paid_cash = ActiveRecord::Type::Boolean.new.cast(
      params[:joint_membership_application][:paid_cash]
    )

    @submitted_application = JointMembershipApplication.new(membership_params)
    @submitted_application.pending = true if paid_cash

    respond_to do |format|
      unless paid_cash == true || PayPalPayments::OrderValidator.call(order_id)
        format.json do
          render json: {
            status: :unhandled_error,
            message: 'Think you\'re sneaky eh?'
          }, status: 400
        end
      end

      if @submitted_application.save(context: :create)
        if @submitted_application.pending == true
          @partial = 'membership_pending_modal.html.erb'
        else
          @partial = 'membership_confirmation_modal.html.erb'
          MembershipMailer.with(application: @submitted_application).signup_confirmation.deliver_later
        end

        format.json do
          render json: {
            status: :created,
            modal: render_to_string(
              partial: @partial
            )
          }
        end
      else
        format.json do
          render json: {
            status: :validation_errors,
            errors: @submitted_application.errors
          }, status: 400
        end
      end
    end
  end

  def validate
    application = JointMembershipApplication.new(membership_params)

    respond_to do |format|
      format.json { render json: { status: :valid } } if application.valid?

      format.json do
        render json: {
          status: :validation_errors,
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

  def membership_params
    params.require(:joint_membership_application).permit(
      :first_name,
      :last_name,
      :order_id,
      :organization,
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
