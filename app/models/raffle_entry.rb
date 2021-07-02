# frozen_string_literal: true

class RaffleEntry < ApplicationRecord
  include EmailValidatable
  attr_accessor :prevalidate

  before_validation :strip_phone_number

  validates :contact, presence: true
  validates :email, presence: true, email: true
  validates :phone_number,
            numericality: true,
            allow_nil: true, if: proc { !phone_number.present? }

  validates :order_id,
            presence: true,
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
