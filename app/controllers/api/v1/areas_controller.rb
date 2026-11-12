# frozen_string_literal: true

module Api
  module V1
    # GET /api/v1/areas        areas that have shareable gauges
    # GET /api/v1/areas/:slug  one area's shareable gauges, with hourly data
    #
    # Only RainGauge rows with api_visible are served. The areas' primary
    # Synoptic stations never are: Synoptic's terms forbid redistribution.
    class AreasController < BaseController
      def index
        areas = WatchedArea.where(id: RainGauge.api_visible.select(:watched_area_id))
                           .includes(:rain_gauges).order(:name)

        render json: {
          areas: areas.map do |area|
            area_json(area).merge(
              url: api_v1_area_url(area.slug),
              gauges: area.rain_gauges.select(&:api_visible).map { |gauge| { id: gauge.slug, name: gauge.name } }
            )
          end
        }
      end

      def show
        area = WatchedArea.find_by(slug: params[:slug])
        gauges = area ? area.rain_gauges.api_visible.to_a : []
        return render json: { error: 'unknown area' }, status: :not_found if gauges.empty?

        render json: area_json(area).merge(
          units: 'in',
          interval: 'PT1H',
          generated_at: Time.current.iso8601,
          gauges: gauges.map { |gauge| report(gauge) }
        )
      end

      private

      def area_json(area)
        { slug: area.slug, name: area.name, latitude: area.latitude&.to_f, longitude: area.longitude&.to_f }
      end

      # Shares the page's cache, so API traffic adds no upstream calls.
      def report(gauge)
        servable = gauge.campbell_cloud? && CampbellCloudPrecipitation.configured?
        body = CampbellCloudPrecipitation.cached(gauge) if servable
        body ? RainGaugeReport.new(gauge, body) : RainGaugeReport.unavailable(gauge)
      end
    end
  end
end
