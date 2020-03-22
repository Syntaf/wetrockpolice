# frozen_string_literal: true

module Area
  class RainyDayOptionsController < BaseController
    before_action :set_watched_area
    before_action :set_meta, only: %i[index]
    respond_to :html, only: %i[index]
    respond_to :json, only: %i[show]

    def index
      @active_rainy_day_option = @watched_area.rainy_day_areas.first
    end

    def show
      @rainy_day_area = @watched_area
                        .rainy_day_areas
                        .joins(:climbing_area)
                        .where(climbing_areas: { id: params[:id].to_i })
                        .first

      respond_with(@rainy_day_area)
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
