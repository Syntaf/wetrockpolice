# frozen_string_literal: true

module Area
  class RainyDayOptionsController < BaseController
    def index
      @active_rainy_day_option = @watched_area.rainy_day_areas.first
    end
  end
end
