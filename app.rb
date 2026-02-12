require "sinatra"
require "json"
require "time"

require_relative "lib/stop_config"
require_relative "lib/muni_client"
require_relative "lib/departure_formatter"

configure do
  set :stop_routes, StopConfig.parse(ENV.fetch("MUNI_STOPS"))
  set :muni_client, MuniClient.new(ENV.fetch("API_KEY_511"))
  set :max_departures, Integer(ENV.fetch("MAX_DEPARTURES", "3"))
end

get "/departures.json" do
  content_type :json

  raw_data = settings.muni_client.fetch_all(settings.stop_routes)
  routes = DepartureFormatter.format(
    raw_data,
    settings.stop_routes,
    max_departures: settings.max_departures
  )

  {
    routes: routes,
    updated_at: Time.now.getlocal.strftime("%-I:%M %p")
  }.to_json
end

get "/preview" do
  raw_data = settings.muni_client.fetch_all(settings.stop_routes)
  @routes = DepartureFormatter.format(
    raw_data,
    settings.stop_routes,
    max_departures: settings.max_departures
  )
  @updated_at = Time.now.getlocal.strftime("%-I:%M %p")

  erb :departures
end

get "/health" do
  content_type :json
  { status: "ok" }.to_json
end
