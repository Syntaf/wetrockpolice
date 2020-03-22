# frozen_string_literal: true

module Area
  class FaqsController < BaseController
    before_action :set_watched_area
    before_action :set_meta

    def index; end

    private

    def set_meta
      @page_title = "#{@watched_area.name} FAQ"
      @page_keywords = <<~TEXT
        Climbing, #{@watched_area.name}, Weather, Rain, Precipitation, Coalition
      TEXT
      @page_description = <<~TEXT
        Frequently asked questions about climbing in #{@watched_area.name} and
        this site.
      TEXT
    end
  end
end
