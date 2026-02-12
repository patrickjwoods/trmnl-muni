require "spec_helper"
require_relative "../app"

RSpec.describe "Sinatra App" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  let(:fixture_path) { File.join(__dir__, "fixtures", "stop_monitoring_response.json") }
  let(:fixture_body) { File.read(fixture_path) }
  let(:api_url) { "https://api.511.org/transit/StopMonitoring" }

  before do
    stub_request(:get, api_url)
      .with(query: hash_including("format" => "json"))
      .to_return(status: 200, body: fixture_body, headers: { "Content-Type" => "application/json" })
  end

  describe "GET /health" do
    it "returns 200 with ok status" do
      get "/health"
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["status"]).to eq("ok")
    end
  end

  describe "GET /departures.json" do
    it "returns 200 with JSON" do
      get "/departures.json"
      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include("application/json")
    end

    it "returns routes array and updated_at" do
      get "/departures.json"
      body = JSON.parse(last_response.body)
      expect(body).to have_key("routes")
      expect(body).to have_key("updated_at")
      expect(body["routes"]).to be_an(Array)
    end

    it "returns departure data for configured routes" do
      get "/departures.json"
      body = JSON.parse(last_response.body)
      routes = body["routes"].map { |r| r["route"] }
      expect(routes).to include("6", "43")
    end

    it "includes departure minutes and times" do
      get "/departures.json"
      body = JSON.parse(last_response.body)
      route6 = body["routes"].find { |r| r["route"] == "6" }
      expect(route6["departures"]).to be_an(Array)

      next unless route6["departures"].any?
      dep = route6["departures"].first
      expect(dep).to have_key("minutes")
      expect(dep).to have_key("time")
    end
  end

  describe "GET /preview" do
    it "returns 200 with HTML" do
      get "/preview"
      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include("text/html")
    end
  end
end
