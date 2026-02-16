module StopConfig
  class ParseError < StandardError; end

  # Parses the MUNI_STOPS env var string into an array of stop ID strings.
  # Format: "15726;15001;..."
  def self.parse(env_string)
    raise ParseError, "MUNI_STOPS is empty or not set" if env_string.nil? || env_string.strip.empty?

    ids = env_string.strip.split(";").map(&:strip).reject(&:empty?)
    raise ParseError, "MUNI_STOPS contains no valid stop IDs" if ids.empty?

    ids.each do |id|
      raise ParseError, "Invalid stop ID '#{id}' — must be numeric" unless id.match?(/\A\d+\z/)
    end

    ids.uniq
  end
end
