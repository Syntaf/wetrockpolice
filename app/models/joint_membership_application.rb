# frozen_string_literal: true

class JointMembershipApplication < ApplicationRecord
  before_validation :strip_phone_number

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :phone_number, :numericality => true

  def strip_phone_number
    if phone_number.nil?
      self.phone_number = phone_number.tr('^0-9', '')
    end
  end
end
