# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    admin { true }
    super_admin { true }
    email { 'johndoe@gmail.com' }
    password { 'ducksareneat' }
    confirmed_at { 1.hour.ago }
  end
end
