# frozen_string_literal: true

module Area
  class BaseController < ApplicationController
    before_action :set_watched_area

    def set_watched_area
      @watched_area = WatchedArea.find_by slug: params[:slug]
    end
  end
end
