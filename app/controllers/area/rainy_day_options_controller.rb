# frozen_string_literal: true

module Area
  class RainyDayOptionsController < BaseController
    before_action :set_watched_area

    def index
      @active_rainy_day_option = @watched_area.rainy_day_areas.first
    end

    def show
      @rainy_day_area = @watched_area
                        .rainy_day_areas
                        .select do |area|
                          area.climbing_area.id == params[:id].to_i
                        end
                        .first

      respond_to do |format|
        format.json do
          render :json => @rainy_day_area,
                 :include => {
                   :climbing_area => {
                     :except => %i[created_at updated_at id],
                     :include => {
                       :location => {
                         :except => %i[created_at updated_at id]
                       }
                     }
                   }
                 },
                 :except => %i[created_at updated_at id]
        end
      end
    end
  end
end
