# frozen_string_literal: true

module Area
  class BaseController < ApplicationController
    private

    def set_watched_area
      @watched_area = WatchedArea.find_by slug: params[:slug]
    end
  end
end
