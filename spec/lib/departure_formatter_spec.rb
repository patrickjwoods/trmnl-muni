require "spec_helper"
require "stop_config"
require "departure_formatter"

RSpec.describe DepartureFormatter do
  let(:fixture_path) { File.join(__dir__, "..", "fixtures", "stop_monitoring_response.json") }
  let(:fixture_data) { JSON.parse(File.read(fixture_path)) }
  let(:now) { Time.parse("2025-01-15T10:02:00Z") }

  describe ".format" do
    it "returns departures for configured routes" do
      stop_routes = StopConfig.parse("6:15726:Downtown;43:15726:Downtown")
      raw_data = { "15726" => fixture_data }

      result = DepartureFormatter.format(raw_data, stop_routes, now: now)

      expect(result.length).to eq(2)
      expect(result[0][:route]).to eq("6")
      expect(result[0][:direction]).to eq("Downtown")
      expect(result[1][:route]).to eq("43")
    end

    it "calculates correct minutes away" do
      stop_routes = StopConfig.parse("6:15726:Downtown")
      raw_data = { "15726" => fixture_data }

      result = DepartureFormatter.format(raw_data, stop_routes, now: now)

      minutes = result[0][:departures].map { |d| d[:minutes] }
      expect(minutes).to eq([3, 12, 25])
    end

    it "limits departures to max_departures" do
      stop_routes = StopConfig.parse("6:15726:Downtown")
      raw_data = { "15726" => fixture_data }

      result = DepartureFormatter.format(raw_data, stop_routes, now: now, max_departures: 2)

      expect(result[0][:departures].length).to eq(2)
    end

    it "filters out routes not in the config" do
      stop_routes = StopConfig.parse("6:15726:Downtown")
      raw_data = { "15726" => fixture_data }

      result = DepartureFormatter.format(raw_data, stop_routes, now: now)

      # Route 7 and 43 exist in fixture but should not appear
      expect(result.length).to eq(1)
      expect(result[0][:route]).to eq("6")
    end

    it "returns empty departures when API response is nil" do
      stop_routes = StopConfig.parse("6:15726:Downtown")
      raw_data = { "15726" => nil }

      result = DepartureFormatter.format(raw_data, stop_routes, now: now)

      expect(result[0][:departures]).to eq([])
    end

    it "drops past departures" do
      stop_routes = StopConfig.parse("6:15726:Downtown")
      raw_data = { "15726" => fixture_data }
      late_now = Time.parse("2025-01-15T10:15:00Z")

      result = DepartureFormatter.format(raw_data, stop_routes, now: late_now)

      # Only the 10:27 departure should remain (12 min away)
      minutes = result[0][:departures].map { |d| d[:minutes] }
      expect(minutes).to eq([12])
    end

    it "includes formatted time strings" do
      stop_routes = StopConfig.parse("6:15726:Downtown")
      raw_data = { "15726" => fixture_data }

      result = DepartureFormatter.format(raw_data, stop_routes, now: now)

      times = result[0][:departures].map { |d| d[:time] }
      times.each do |t|
        expect(t).to match(/\d{1,2}:\d{2} [AP]M/)
      end
    end

    it "falls back to ExpectedArrivalTime when departure time is absent" do
      modified_data = JSON.parse(fixture_data.to_json)
      visits = modified_data.dig("ServiceDelivery", "StopMonitoringDelivery", "MonitoredStopVisit")
      visits.each do |v|
        v["MonitoredVehicleJourney"]["MonitoredCall"].delete("ExpectedDepartureTime")
      end

      stop_routes = StopConfig.parse("6:15726:Downtown")
      raw_data = { "15726" => modified_data }

      result = DepartureFormatter.format(raw_data, stop_routes, now: now)

      # Should still have departures using arrival times
      expect(result[0][:departures]).not_to be_empty
    end

    it "sorts departures by minutes ascending" do
      stop_routes = StopConfig.parse("43:15726:Downtown")
      raw_data = { "15726" => fixture_data }

      result = DepartureFormatter.format(raw_data, stop_routes, now: now)

      minutes = result[0][:departures].map { |d| d[:minutes] }
      expect(minutes).to eq(minutes.sort)
    end
  end
end
