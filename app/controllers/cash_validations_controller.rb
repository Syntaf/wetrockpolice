# frozen_string_literal: true

class CashValidationsController < ApplicationController
  respond_to :html, only: %i[index]
  respond_to :json, except: %i[index]
  before_action :authenticate_user!

  def index
    @pending_payments = JointMembershipApplication.where(pending: true)
  end

  def update
    payment = JointMembershipApplication.find(params[:id])
    payment.pending = false

    payment.save!
    render json: { status: :ok }, status: :ok
  rescue ActiveRecord::RecordInvalid
    render json: { status: :bad_request }, status: :bad_request
  end

  def destroy
    payment = JointMembershipApplication.find(params[:id])
    payment.delete

    render json: { status: :ok }, status: :ok
  end
end
