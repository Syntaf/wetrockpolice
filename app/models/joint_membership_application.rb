# frozen_string_literal: true

class JointMembershipApplication < ApplicationRecord
  include EmailValidatable

  attr_accessor :prevalidate

  before_validation :strip_phone_number

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, email: true
  validates :phone_number, numericality: true, allow_nil: true

  validates :organization, presence: true

  validates :street_line_one, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zipcode, numericality: true, length: { is: 5 }
  validates :shirt_size, presence: true, if: :selected_shirt?
  validates :delivery_method, presence: true, if: :selected_shirt?
  validates :order_id,
            presence: true,
            if: :paid_with_card?,
            unless: :prevalidating?

  def paid_with_card?
    paid_cash == false
  end

  def selected_shirt?
    local_shirt == true || access_fund_shirt == true
  end

  private

  def prevalidating?
    prevalidate || false
  end

  def strip_phone_number
    return if phone_number.nil?

    self.phone_number = phone_number.tr('^0-9', '')
  end
end
