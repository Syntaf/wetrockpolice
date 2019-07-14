class RedrockController < ApplicationController
  def index
    @page_title = "Climbing in Red Rock Canyon"
    @page_description = "View real time precipitation data for climbing in Red Rock Canyon, find rainy day options when weather is looking bleak, and view upcoming forecasts for the area. Wetrockpolice is dedicated to helping keep you informed on when Red Rock is safe to climb"
    @page_keywords = "Climbing, Red Rock Canyon, Las Vegas, Weather, Rain, Precipitation"
  end

  def faq
    @page_title = "Red Rock Climbing FAQ"
    @page_description = "Generally, you should avoid climbing on wet sandstone at Red Rock for anywhere between 24 and 72 hours, depending on the amount of sunlight and temperature in the following days."
    @page_keywords = "Climbing, Red Rock Canyon, Las Vegas, FAQ, Rain, Precipitation"
  end

  def rainy_day_options
    @page_title = "Red Rock Rainy Day Climbing Options"
    @page_description = "The Las Vegas area contains a multitude high quality crags suitable for any weather, be it rain sleet or snow. Integrated with mountain project and curated by locals, these crags are great options for rainy days in the city."
    @page_keywords = "Climbing, Red Rock Canyon, Crags, Mountain Project, Rain, Precipitation, Weather"

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
