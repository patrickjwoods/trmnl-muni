require "time"

module DepartureFormatter
  # Transforms raw API data into display-ready departure info grouped by stop and line.
  #
  # raw_data: { stop_id => parsed_json_or_nil } from MuniClient#fetch_all
  # stop_ids: [String, ...] from StopConfig.parse
  # max_departures: max departures per line
  #
  # Returns array of stop hashes:
  #   [{ stop_name:, lines: [{ line:, destination:, departures: [{ minutes:, time: }] }] }]
  def self.format(raw_data, stop_ids, now: Time.now, max_departures: 3)
    stop_ids.map do |stop_id|
      api_response = raw_data[stop_id]
      visits = extract_visits(api_response)

      stop_name = extract_stop_name(visits, stop_id)
      lines = group_by_line(visits, now, max_departures)

      { stop_name: stop_name, lines: lines }
    end
  end

  private

  def self.extract_visits(api_response)
    return [] if api_response.nil?

    visits = api_response.dig(
      "ServiceDelivery",
      "StopMonitoringDelivery",
      "MonitoredStopVisit"
    )
    visits.is_a?(Array) ? visits : []
  end

  def self.extract_stop_name(visits, stop_id)
    return "Stop #{stop_id}" if visits.empty?

    visits.first.dig("MonitoredVehicleJourney", "MonitoredCall", "StopPointName") ||
      "Stop #{stop_id}"
  end

  def self.group_by_line(visits, now, max_departures)
    by_line = {}

    visits.each do |visit|
      journey = visit["MonitoredVehicleJourney"]
      next unless journey

      line_ref = journey["LineRef"]
      next unless line_ref

      departure_time = parse_departure_time(visit)
      next unless departure_time

      minutes = ((departure_time - now) / 60.0).round
      next if minutes < 0

      by_line[line_ref] ||= {
        line: line_ref,
        name: journey["PublishedLineName"] || line_ref,
        destination: journey["DestinationName"] || journey["DestinationDisplay"] || "",
        departures: []
      }

      by_line[line_ref][:departures] << {
        minutes: minutes,
        time: departure_time.getlocal.strftime("%-I:%M %p")
      }
    end

    by_line.values.each do |line_data|
      line_data[:departures].sort_by! { |d| d[:minutes] }
      line_data[:departures] = line_data[:departures].first(max_departures)
    end

    by_line.values.sort_by { |l| l[:departures].first&.[](:minutes) || Float::INFINITY }
  end

  def self.parse_departure_time(visit)
    call = visit.dig("MonitoredVehicleJourney", "MonitoredCall")
    return nil unless call

    time_str = call["ExpectedDepartureTime"] || call["ExpectedArrivalTime"]
    return nil unless time_str

    Time.parse(time_str)
  rescue ArgumentError
    nil
  end
end
