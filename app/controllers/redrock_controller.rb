class RedrockController < ApplicationController
  def index
  end

  def faq
  end

  def rainy_day_options
    watched_area_repo = WatchedAreaRepository.new()
    @watched_area = watched_area_repo.get_watched_area('redrock')

    @active_rainy_day_option = @watched_area.rainy_day_areas.first
  end

  def climbing_area
    watched_area_repo = WatchedAreaRepository.new()

    @watched_area = watched_area_repo.get_watched_area('redrock')
    @rainy_day_area = @watched_area.rainy_day_areas.joins(:climbing_area).where(:climbing_areas => {:name => params[:name]}).first

    respond_to do |format|
      format.json { 
        render :json => @rainy_day_area, 
        :include => {
          :climbing_area => {
            :except => [:created_at, :updated_at, :id],
            :include => {
              :location => {
                :except => [:created_at, :updated_at, :id]
              }
            }
          }
        },
        :except => [:created_at, :updated_at, :id]
      }
    end
  end
end
