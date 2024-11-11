# frozen_string_literal: true

module ApplicationHelper
  def development_mode?
    Rails.env.development? && ActiveModel::Type::Boolean.new.cast(ENV['MOCK_WEATHER_DATA'])
  end
end
