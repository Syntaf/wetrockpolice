# frozen_string_literal: true

class JointMembershipApplication < ApplicationRecord
  include EmailValidatable
  attr_accessor :prevalidate

  has_many :shirt_orders, dependent: :destroy
  accepts_nested_attributes_for :shirt_orders
  validates_associated :shirt_orders

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
  validates :delivery_method, presence: true, if: proc { |a| a.shirt_orders.any? }

  validates :order_id,
            presence: true,
            if: :paid_with_card?,
            unless: :prevalidating?

  def paid_with_card?
    paid_cash == false
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
