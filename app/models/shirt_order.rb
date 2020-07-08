# frozen_string_literal: true

class ShirtOrder < ApplicationRecord
  belongs_to :joint_membership_application

  validates :shirt_type, inclusion: { in: %w[local_shirt access_fund_shirt] }
  validates :shirt_size, presence: true
  validates :shirt_color, presence: true
end
