# frozen_string_literal: true

class WatchedAreaController < ApplicationController
  before_action :set_watched_area

  def index

  end

  def set_watched_area
    @watched_area = WatchedArea.find_by slug: params[:slug]
  end
end
