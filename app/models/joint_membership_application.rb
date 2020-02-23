# frozen_string_literal: true

class JointMembershipApplication < ApplicationRecord
  include EmailValidatable

  before_validation :strip_phone_number

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, email: true
  validates :phone_number, numericality: true, allow_nil: true

  validates :organization, presence: true

  validates :street_line_one, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zipcode, numericality: true, length: { is: 5 }
  validates :order_id, presence: true, if: :paid_with_card?, on: :prevalidated
  validates :shirt_size, presence: true, if: :selected_shirt?

  def paid_with_card?
    paid_cash == false
  end

  def selected_shirt?
    local_shirt == true || access_fund_shirt == true
  end

  private

  def strip_phone_number
    return if phone_number.nil?

    self.phone_number = phone_number.tr('^0-9', '')
  end
end
