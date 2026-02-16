require "spec_helper"
require "departure_formatter"

RSpec.describe DepartureFormatter do
  let(:fixture_path) { File.join(__dir__, "..", "fixtures", "stop_monitoring_response.json") }
  let(:fixture_data) { JSON.parse(File.read(fixture_path)) }
  let(:now) { Time.parse("2025-01-15T10:02:00Z") }

  describe ".format" do
    it "returns stops with lines grouped by line ref" do
      raw_data = { "15726" => fixture_data }

      result = DepartureFormatter.format(raw_data, ["15726"], now: now)

      expect(result.length).to eq(1)
      stop = result[0]
      expect(stop[:stop_name]).to eq("Church St & Duboce Ave")
      line_refs = stop[:lines].map { |l| l[:line] }
      expect(line_refs).to include("6", "43", "7")
    end

    it "includes all lines from the stop without filtering" do
      raw_data = { "15726" => fixture_data }

      result = DepartureFormatter.format(raw_data, ["15726"], now: now)

      lines = result[0][:lines]
      expect(lines.length).to eq(3) # 6, 43, and 7
    end

    it "calculates correct minutes away" do
      raw_data = { "15726" => fixture_data }

      result = DepartureFormatter.format(raw_data, ["15726"], now: now)

      line6 = result[0][:lines].find { |l| l[:line] == "6" }
      minutes = line6[:departures].map { |d| d[:minutes] }
      expect(minutes).to eq([3, 12, 25])
    end

    it "limits departures per line to max_departures" do
      raw_data = { "15726" => fixture_data }

      result = DepartureFormatter.format(raw_data, ["15726"], now: now, max_departures: 2)

      line6 = result[0][:lines].find { |l| l[:line] == "6" }
      expect(line6[:departures].length).to eq(2)
    end

    it "includes line name and destination" do
      raw_data = { "15726" => fixture_data }

      result = DepartureFormatter.format(raw_data, ["15726"], now: now)

      line6 = result[0][:lines].find { |l| l[:line] == "6" }
      expect(line6[:name]).to eq("6-Haight/Parnassus")
      expect(line6[:destination]).to eq("Downtown")
    end

    it "returns empty lines when API response is nil" do
      raw_data = { "15726" => nil }

      result = DepartureFormatter.format(raw_data, ["15726"], now: now)

      expect(result[0][:stop_name]).to eq("Stop 15726")
      expect(result[0][:lines]).to eq([])
    end

    it "drops past departures" do
      raw_data = { "15726" => fixture_data }
      late_now = Time.parse("2025-01-15T10:15:00Z")

      result = DepartureFormatter.format(raw_data, ["15726"], now: late_now)

      line6 = result[0][:lines].find { |l| l[:line] == "6" }
      minutes = line6[:departures].map { |d| d[:minutes] }
      expect(minutes).to eq([12])
    end

    it "includes formatted time strings" do
      raw_data = { "15726" => fixture_data }

      result = DepartureFormatter.format(raw_data, ["15726"], now: now)

      line6 = result[0][:lines].find { |l| l[:line] == "6" }
      line6[:departures].each do |d|
        expect(d[:time]).to match(/\d{1,2}:\d{2} [AP]M/)
      end
    end

    it "falls back to ExpectedArrivalTime when departure time is absent" do
      modified_data = JSON.parse(fixture_data.to_json)
      visits = modified_data.dig("ServiceDelivery", "StopMonitoringDelivery", "MonitoredStopVisit")
      visits.each do |v|
        v["MonitoredVehicleJourney"]["MonitoredCall"].delete("ExpectedDepartureTime")
      end

      raw_data = { "15726" => modified_data }

      result = DepartureFormatter.format(raw_data, ["15726"], now: now)

      expect(result[0][:lines]).not_to be_empty
      line6 = result[0][:lines].find { |l| l[:line] == "6" }
      expect(line6[:departures]).not_to be_empty
    end

    it "sorts lines by soonest departure" do
      raw_data = { "15726" => fixture_data }

      result = DepartureFormatter.format(raw_data, ["15726"], now: now)

      first_departures = result[0][:lines].map { |l| l[:departures].first[:minutes] }
      expect(first_departures).to eq(first_departures.sort)
    end

    it "handles multiple stops" do
      raw_data = { "15726" => fixture_data, "15727" => fixture_data }

      result = DepartureFormatter.format(raw_data, ["15726", "15727"], now: now)

      expect(result.length).to eq(2)
      expect(result[0][:stop_name]).to eq("Church St & Duboce Ave")
      expect(result[1][:stop_name]).to eq("Church St & Duboce Ave")
    end
  end
end
