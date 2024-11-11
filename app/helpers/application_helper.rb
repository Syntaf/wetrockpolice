# frozen_string_literal: true

module ApplicationHelper
  def development_mode?
    Rails.env.development? && ActiveModel::Type::Boolean.new.cast(ENV['MOCK_WEATHER_DATA'])
  end

  def watched_area_bg_image
    case @watched_area.slug
    when 'redrock'
      'media/images/redrock-winter-2020-hero.jpg'
    when 'castlerock'
      'media/images/castlerock/hero-image.jpg'
    when 'stoneypoint'
      'media/images/stoneypoint/hero-image.png'
    end
  end
end
