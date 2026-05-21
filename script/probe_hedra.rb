# Probes the Hedra API to understand which endpoints are available.
# Run with: bin/rails runner script/probe_hedra.rb
require "net/http"
require "json"

api_key = Rails.application.credentials.dig(:hedra, :api_key) or abort("No Hedra api_key in credentials")

# Hedra public API base — current docs at https://docs.hedra.com
BASE = "https://api.hedra.com/web-app/public"

def get(url, api_key)
  uri = URI(url)
  req = Net::HTTP::Get.new(uri)
  req["X-API-Key"] = api_key
  req["Accept"] = "application/json"
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  [ res.code, res.body ]
end

puts "── GET /models ──"
code, body = get("#{BASE}/models", api_key)
puts "HTTP #{code}"
puts body.to_s[0, 600]
