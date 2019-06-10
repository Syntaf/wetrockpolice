class RedrockController < ApplicationController
  def index
  end

  def faq
  end

  def rainy_day_options
    watched_area_repo = WatchedAreaRepository.new()

    @watched_area = watched_area_repo.get_watched_area('redrock')
  end
end
