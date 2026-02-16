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

    it "returns stops array and updated_at" do
      get "/departures.json"
      body = JSON.parse(last_response.body)
      expect(body).to have_key("stops")
      expect(body).to have_key("updated_at")
      expect(body["stops"]).to be_an(Array)
    end

    it "returns stop with stop_name and lines" do
      get "/departures.json"
      body = JSON.parse(last_response.body)
      stop = body["stops"].first
      expect(stop).to have_key("stop_name")
      expect(stop).to have_key("lines")
      expect(stop["lines"]).to be_an(Array)
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
