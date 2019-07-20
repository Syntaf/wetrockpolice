class WatchedAreaController < ApplicationController
  before_action :set_watched_area

  def index
    @watched_area_name = @watched_area.name

    @page_title = "Climbing in #{@watched_area_name}"
    @page_description = @default_description
    @page_keywords = base_keywords
  end

  def faq
    @page_title = "#{@watched_area_name} Climbing FAQ"
    @page_description = @default_description
    @page_keywords = base_keywords + ", FAQ"
  end

  def rainy_day_options
    @page_title = "#{@watched_area_name} Climbing Options"
    @page_description = @default_description
    @page_keywords = base_keywords + ", crags, rainy day options, mountain project"
    @active_rainy_day_option = @watched_area.rainy_day_areas.first
  end

  def climbing_area
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

  def set_watched_area
    @watched_area = WatchedArea.find_by(id: params[:watched_area_id])
    @watched_area_name = @watched_area.name
    @default_description = @page_description = "View real time precipitation data for climbing in #{@watched_area_name}, find rainy day options when weather is looking bleak, and view upcoming forecasts for the area. Wetrockpolice is dedicated to helping keep you informed on when #{@watched_area_name} is safe to climb"
  end

  def base_keywords
    "Climbing, #{@watched_area_name}, Weather, Rain, Precipitation"
  end
end