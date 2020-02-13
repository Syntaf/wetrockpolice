# frozen_string_literal: true

class MembershipsController < ApplicationController
  def new
    @watched_area = WatchedArea.find_by(id: params[:watched_area_id])
    @joint_membership = JointMembershipApplication.new
  end

  def create
    order_id = params[:joint_membership_application][:order_id]
    paid_cash = ActiveRecord::Type::Boolean.new.cast(
      params[:joint_membership_application][:paid_cash]
    )

    unless paid_cash == true || PayPalPayments::OrderValidator.call(order_id)
      redirect_to :redrock_sncc,
                  :flash => { :invalid_order => true } and return
    end

    JointMembershipApplication.create!(membership_app_params)

    redirect_to :redrock_sncc,
                :flash => { :membership_successful => true }
  end

  private

  def membership_app_params
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
