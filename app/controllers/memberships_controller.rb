# frozen_string_literal: true

class MembershipsController < ApplicationController
  def new
    @watched_area = WatchedArea.find_by(id: params[:watched_area_id])
    @joint_membership = JointMembershipApplication.new
  end

  def create
    order_id = params[:joint_membership_application][:order_id]

    if PayPalPayments::OrderValidator.call(order_id)
      @membership_app = JointMembershipApplication.create!(membership_app_params)
    end
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
      :shirt_type,
      :shirt_size)
  end
end
