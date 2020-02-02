# frozen_string_literal: true

class MembershipsController < ApplicationController
  before_action :create_paypal_client, only: :create

  def new
    @watched_area = WatchedArea.find_by(id: params[:watched_area_id])
    @joint_membership = JointMembershipApplication.new
  end

  def create
    order_id = params[:joint_membership_application][:order_id]
    
    if @client.order_valid?(order_id)
      @membership_app = JointMembershipApplication.create!(membership_app_params)
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

  def create_paypal_client
    @client = ::PaymentServices::PaypalClient.new
  end
end
