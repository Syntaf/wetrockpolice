# frozen_string_literal: true

module Area
  class RainyDayOptionsController < BaseController
    before_action :set_watched_area
    before_action :set_meta, only: %i[index]

    def index
      @active_rainy_day_option = @watched_area.rainy_day_areas.first
    end

    def show
      @rainy_day_area = @watched_area
                        .rainy_day_areas
                        .joins(:climbing_area)
                        .where(climbing_areas: { id: params[:id].to_i })
                        .first

      respond_to do |format|
        format.json { render json: @rainy_day_area }
      end
    end

    private

    def set_meta
      @page_title = "Alternatives for #{@watched_area.name}"
      @page_keywords = <<~TEXT
        Climbing, #{@watched_area.name}, Weather, Rain, Precipitation, Topo
      TEXT
      @page_description = <<~TEXT
        Alternative climbing areas around #{@watched_area.name} for when weather
        is looking bleak. Read about drive times, area descriptions, and mountain
        project topos.
      TEXT
    end
  end
end
