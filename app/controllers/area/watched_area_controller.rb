# frozen_string_literal: true

module Area
  class WatchedAreaController < BaseController
    before_action :set_watched_area
    before_action :set_meta

    def index; end

    private

    def set_meta
      @page_title = "Climbing in #{@watched_area.name}"
      @page_keywords = <<~TEXT
        Climbing, #{@watched_area.name}, Weather, Rain, Precipitation
      TEXT
      @page_description = <<~TEXT
        Real-time precipitation data for climbing in #{@watched_area.name}.
        View historical rain data, upcoming forecasts, and rainy day alternatives
        for when weather goes south
      TEXT
    end
  end
end
