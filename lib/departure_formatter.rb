require "time"

module DepartureFormatter
  # Transforms raw API data into display-ready departure info.
  #
  # raw_data: { stop_id => parsed_json_or_nil } from MuniClient#fetch_all
  # stop_routes: [StopRoute, ...] from StopConfig.parse
  # max_departures: max departures per route/direction combo
  #
  # Returns array of hashes:
  #   [{ route:, direction:, departures: [{ minutes:, time: }, ...] }, ...]
  def self.format(raw_data, stop_routes, now: Time.now, max_departures: 3)
    stop_routes.map do |sr|
      api_response = raw_data[sr.stop_id]
      departures = extract_departures(api_response, sr.route, now, max_departures)

      {
        route: sr.route,
        direction: sr.direction_label,
        departures: departures
      }
    end
  end

  private

  def self.extract_departures(api_response, route, now, max_departures)
    return [] if api_response.nil?

    visits = api_response.dig(
      "ServiceDelivery",
      "StopMonitoringDelivery",
      "MonitoredStopVisit"
    )
    return [] unless visits.is_a?(Array)

    matching = visits.select do |visit|
      visit.dig("MonitoredVehicleJourney", "LineRef") == route
    end

    departures = matching.filter_map do |visit|
      departure_time = parse_departure_time(visit)
      next unless departure_time

      minutes = ((departure_time - now) / 60.0).round
      next if minutes < 0

      {
        minutes: minutes,
        time: departure_time.getlocal.strftime("%-I:%M %p")
      }
    end

    departures.sort_by { |d| d[:minutes] }.first(max_departures)
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
