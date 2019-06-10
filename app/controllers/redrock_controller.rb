class RedrockController < ApplicationController
  def index
  end

  def faq
  end

  def rainy_day_options
    rainyDayRepo = RainyDayRepository.new()

    @rainyDayAreas = rainyDayRepo.get_watched_area('redrock')
  end
end
