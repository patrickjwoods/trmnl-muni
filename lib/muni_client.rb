require "net/http"
require "uri"
require "json"

class MuniClient
  API_BASE = "https://api.511.org/transit/StopMonitoring".freeze
  TIMEOUT = 10

  def initialize(api_key)
    @api_key = api_key
  end

  # Fetches stop monitoring data for a single stop.
  # Returns parsed JSON hash, or nil on error.
  def fetch_stop(stop_id)
    uri = URI(API_BASE)
    uri.query = URI.encode_www_form(
      api_key: @api_key,
      agency: "SF",
      stopCode: stop_id,
      format: "json"
    )

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT

    response = http.get(uri.request_uri)

    case response.code.to_i
    when 200
      body = strip_bom(response.body)
      JSON.parse(body)
    when 429
      warn "[MuniClient] Rate limited (429) for stop #{stop_id}"
      nil
    else
      warn "[MuniClient] HTTP #{response.code} for stop #{stop_id}"
      nil
    end
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    warn "[MuniClient] Timeout fetching stop #{stop_id}: #{e.message}"
    nil
  rescue StandardError => e
    warn "[MuniClient] Error fetching stop #{stop_id}: #{e.message}"
    nil
  end

  # Fetches data for all unique stops referenced in stop_routes.
  # Deduplicates by stop_id to minimize API calls.
  # Returns { stop_id => parsed_json_or_nil }
  def fetch_all(stop_routes)
    unique_stop_ids = stop_routes.map(&:stop_id).uniq
    results = {}

    unique_stop_ids.each do |stop_id|
      results[stop_id] = fetch_stop(stop_id)
    end

    results
  end

  private

  # 511.org API is known to prepend a UTF-8 BOM to JSON responses
  def strip_bom(text)
    text.force_encoding("UTF-8").delete_prefix("\xEF\xBB\xBF".force_encoding("UTF-8"))
  end
end
