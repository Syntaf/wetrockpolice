# frozen_string_literal: true

class MembershipsController < ApplicationController
  def new
    @watched_area = WatchedArea.find_by(id: params[:watched_area_id])
    @joint_membership = JointMembershipApplication.new
  end

  def create
    order_id = params[:joint_membership_application][:order_id]
    order_id = '8Y7241789T5516533'
    paid_cash = ActiveRecord::Type::Boolean.new.cast(
      params[:joint_membership_application][:paid_cash]
    )

    @submitted_application = JointMembershipApplication.new(membership_params)

    respond_to do |format|
      unless paid_cash == true || PayPalPayments::OrderValidator.call(order_id)
        format.json do
          render json: {
            status: :unhandled_error,
            message: 'Think you\'re sneaky eh?'
          }, status: 400
        end
      end

      if @submitted_application.save
        MembershipMailer.with(application: @submitted_application).payment_complete.deliver_later

        format.json { render json: { status: :created } }
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
