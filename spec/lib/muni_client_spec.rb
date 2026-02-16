require "spec_helper"
require "muni_client"

RSpec.describe MuniClient do
  let(:client) { MuniClient.new("test_api_key") }
  let(:fixture_path) { File.join(__dir__, "..", "fixtures", "stop_monitoring_response.json") }
  let(:fixture_body) { File.read(fixture_path) }
  let(:api_url) { "https://api.511.org/transit/StopMonitoring" }

  def stub_stop_request(stop_id, body: fixture_body, status: 200)
    stub_request(:get, api_url)
      .with(query: hash_including("stopCode" => stop_id))
      .to_return(status: status, body: body, headers: { "Content-Type" => "application/json" })
  end

  describe "#fetch_stop" do
    it "fetches and parses a successful response" do
      stub_stop_request("15726")

      result = client.fetch_stop("15726")
      expect(result).to be_a(Hash)
      expect(result.dig("ServiceDelivery", "StopMonitoringDelivery", "MonitoredStopVisit")).to be_an(Array)
    end

    it "strips BOM from response body" do
      bom_body = "\xEF\xBB\xBF#{fixture_body}"
      stub_stop_request("15726", body: bom_body)

      result = client.fetch_stop("15726")
      expect(result).to be_a(Hash)
    end

    it "returns nil on 429 rate limit" do
      stub_stop_request("15726", status: 429, body: "Rate limited")

      result = client.fetch_stop("15726")
      expect(result).to be_nil
    end

    it "returns nil on 500 server error" do
      stub_stop_request("15726", status: 500, body: "Internal Server Error")

      result = client.fetch_stop("15726")
      expect(result).to be_nil
    end

    it "returns nil on timeout" do
      stub_request(:get, api_url)
        .with(query: hash_including("stopCode" => "15726"))
        .to_timeout

      result = client.fetch_stop("15726")
      expect(result).to be_nil
    end
  end

  describe "#fetch_all" do
    it "fetches each stop ID" do
      stop_ids = ["15726", "15727"]

      stub_15726 = stub_stop_request("15726")
      stub_15727 = stub_stop_request("15727")

      results = client.fetch_all(stop_ids)

      expect(stub_15726).to have_been_requested.once
      expect(stub_15727).to have_been_requested.once
      expect(results.keys).to contain_exactly("15726", "15727")
    end

    it "handles partial failures gracefully" do
      stop_ids = ["15726", "15727"]

      stub_stop_request("15726")
      stub_stop_request("15727", status: 500, body: "error")

      results = client.fetch_all(stop_ids)

      expect(results["15726"]).to be_a(Hash)
      expect(results["15727"]).to be_nil
    end
  end
end
