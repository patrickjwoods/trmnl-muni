StopRoute = Struct.new(:route, :stop_id, :direction_label, keyword_init: true)

module StopConfig
  class ParseError < StandardError; end

  # Parses the MUNI_STOPS env var string into an array of StopRoute structs.
  # Format: "route:stop_id:direction_label;route:stop_id:direction_label;..."
  def self.parse(env_string)
    raise ParseError, "MUNI_STOPS is empty or not set" if env_string.nil? || env_string.strip.empty?

    env_string.strip.split(";").map do |entry|
      parts = entry.strip.split(":")
      unless parts.length == 3
        raise ParseError, "Invalid stop config '#{entry.strip}' — expected format route:stop_id:direction_label"
      end

      route, stop_id, direction_label = parts.map(&:strip)

      raise ParseError, "Route cannot be blank in '#{entry.strip}'" if route.empty?
      raise ParseError, "Stop ID cannot be blank in '#{entry.strip}'" if stop_id.empty?
      raise ParseError, "Direction label cannot be blank in '#{entry.strip}'" if direction_label.empty?

      StopRoute.new(route: route, stop_id: stop_id, direction_label: direction_label)
    end
  end

  # Groups StopRoutes by stop_id for API call deduplication.
  # Returns { stop_id => [StopRoute, ...] }
  def self.group_by_stop(stop_routes)
    stop_routes.group_by(&:stop_id)
  end
end
