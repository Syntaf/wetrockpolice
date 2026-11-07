# frozen_string_literal: true

namespace :campbell_cloud do
  # Lists a CampbellCloud station's datastreams so you can pick the
  # campbell_table / campbell_field for a RainGauge row:
  #
  #   bin/rails "campbell_cloud:datastreams[01a0c4e4-b777-71d7-8106-6f6d83d0c84a]"
  #
  # Needs the CAMPBELL_CLOUD_* variables from .env.
  desc 'List the datastreams (table.field => id) on a CampbellCloud station'
  task :datastreams, [:station] => :environment do |_task, args|
    abort 'usage: bin/rails "campbell_cloud:datastreams[<station uuid>]"' if args[:station].blank?
    abort 'CAMPBELL_CLOUD_* credentials are not set' unless CampbellCloudPrecipitation.configured?

    gauge = RainGauge.new(station: args[:station])
    datastreams = CampbellCloudPrecipitation.new(gauge).send(
      :authorized_get, "/api/v1/organizations/#{ENV.fetch('CAMPBELL_CLOUD_ORGANIZATION_ID')}/datastreams",
      { stationId: args[:station], limit: 250 }
    )

    Array(datastreams).each do |ds|
      puts format('%-40s %s', "#{ds.dig('metadata', 'table')}.#{ds.dig('metadata', 'field')}", ds['id'])
    end
  end
end
