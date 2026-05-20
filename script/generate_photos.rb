# SnagRadar marketing photo pipeline.
# Hedra (Flux 1.1 Pro)  →  Tinify (TinyPNG)  →  app/assets/images/photos/
#
# Usage: bin/rails runner script/generate_photos.rb [target...]
#   target = a key from SHOT_LIST below, or "all"
#
# Idempotent: skips any target whose final compressed file already exists.

require "net/http"
require "json"
require "fileutils"

# ---- credentials --------------------------------------------------------
HEDRA_API_KEY  = Rails.application.credentials.dig(:hedra,  :api_key) or abort("Missing hedra.api_key")
TINIFY_API_KEY = Rails.application.credentials.dig(:tinify, :api_key) or abort("Missing tinify.api_key")

HEDRA_BASE = "https://api.hedra.com/web-app/public"
FLUX_MODEL = "45e44fc3-691b-4e87-8b55-e8ac30bc95d7" # fal/flux-11-pro

PHOTOS_DIR = Rails.root.join("app", "assets", "images", "photos")
FileUtils.mkdir_p(PHOTOS_DIR)

# ---- shot list ----------------------------------------------------------
# Each shot drives one Hedra call. Prompts are tuned for editorial portrait
# realism — soft natural light, plain backdrop, gentle expression, no logos,
# no readable text. UK construction-aftercare context.
SHOT_LIST = {
  "eleanor-marshall" => {
    aspect: "3:4", resolution: "720p",
    prompt: <<~PROMPT.gsub("\n", " ").strip
      Editorial portrait of Eleanor Marshall, a 38-year-old British woman,
      warm friendly smile, short auburn hair, wearing a smart navy blouse,
      sitting at a clean modern office desk with a laptop softly out of focus,
      bright natural window light from the side, shallow depth of field,
      photorealistic, medium close-up, magazine quality, calm professional mood
    PROMPT
  },
  "daniel-thornton" => {
    aspect: "3:4", resolution: "720p",
    prompt: <<~PROMPT.gsub("\n", " ").strip
      Editorial portrait of Daniel Thornton, a 42-year-old British site manager,
      slight stubble, short dark hair, hi-vis orange jacket over a navy fleece,
      construction site softly blurred in background showing pale brick housing,
      overcast daylight, looking confidently at camera with a small relaxed smile,
      photorealistic, medium close-up, magazine quality, hands relaxed
    PROMPT
  },
  "marisa-kovacs" => {
    aspect: "3:4", resolution: "720p",
    prompt: <<~PROMPT.gsub("\n", " ").strip
      Editorial portrait of Marisa Kovacs, a 45-year-old aftercare manager,
      shoulder-length brunette hair, glasses, smart cream knit cardigan,
      light beige office wall behind her, soft natural light from front-left,
      warm welcoming expression, photorealistic, medium close-up,
      magazine quality, hands clasped lightly in front
    PROMPT
  },
  "phil-roberts" => {
    aspect: "3:4", resolution: "720p",
    prompt: <<~PROMPT.gsub("\n", " ").strip
      Editorial portrait of Phil Roberts, a 50-year-old British plumber subcontractor,
      salt-and-pepper close-cropped hair, navy work polo shirt, sleeves rolled up,
      holding a smartphone, leaning against a clean white-tiled wall,
      bright workshop daylight, calm satisfied half-smile, photorealistic,
      medium close-up, magazine quality
    PROMPT
  }
}.freeze

# ---- helpers ------------------------------------------------------------
def http_json(method, url, api_key, body = nil)
  uri = URI(url)
  req = case method
        when :get  then Net::HTTP::Get.new(uri)
        when :post then Net::HTTP::Post.new(uri)
        end
  req["X-API-Key"] = api_key
  req["Accept"]    = "application/json"
  if body
    req["Content-Type"] = "application/json"
    req.body = body.to_json
  end
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 60) { |h| h.request(req) }
  [res.code.to_i, (JSON.parse(res.body) rescue res.body)]
end

def hedra_post(path, body)
  http_json(:post, "#{HEDRA_BASE}#{path}", HEDRA_API_KEY, body)
end

def hedra_get(path)
  http_json(:get, "#{HEDRA_BASE}#{path}", HEDRA_API_KEY)
end

def submit_generation(prompt:, aspect:, resolution:)
  code, body = hedra_post("/generations", {
    type: "image",
    ai_model_id: FLUX_MODEL,
    text_prompt: prompt,
    aspect_ratio: aspect,
    resolution: resolution
  })
  abort "Hedra submit failed (#{code}): #{body.inspect}" unless (200..299).include?(code)
  body
end

def poll_until_complete(generation_id, max_wait_s: 240)
  started = Time.now
  loop do
    code, body = hedra_get("/generations/#{generation_id}/status")
    abort "Hedra status failed (#{code}): #{body.inspect}" unless (200..299).include?(code)

    status = body["status"]
    case status
    when "complete", "succeeded"
      return body
    when "failed", "error"
      abort "Hedra generation failed: #{body.inspect}"
    end

    if Time.now - started > max_wait_s
      abort "Hedra poll timed out after #{max_wait_s}s. Last status: #{status}"
    end
    sleep 3
  end
end

# Hedra's status endpoint returns null urls for image gens — the actual URL lives
# in the assets list. We look up the asset by id and pull asset.url.
def fetch_asset_url(asset_id)
  code, body = hedra_get("/assets?type=image&limit=50")
  abort "Hedra assets list failed (#{code}): #{body.inspect}" unless (200..299).include?(code)
  found = Array(body).find { |a| a["id"] == asset_id }
  abort "Asset #{asset_id} not found in latest 50 image assets" unless found
  found.dig("asset", "url") or abort "No asset.url on #{asset_id}: #{found.inspect}"
end

def download(url, to_path)
  uri = URI(url)
  Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(Net::HTTP::Get.new(uri)) do |res|
      File.open(to_path, "wb") { |f| res.read_body { |chunk| f.write(chunk) } }
    end
  end
end

def tinify_compress!(path)
  raw = File.binread(path)
  # POST raw image bytes to Tinify; response has a Location header to the shrunk file
  uri = URI("https://api.tinify.com/shrink")
  req = Net::HTTP::Post.new(uri)
  req.basic_auth("api", TINIFY_API_KEY)
  req["Content-Type"] = "application/octet-stream"
  req.body = raw

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h| h.request(req) }
  unless res.code.to_i == 201
    warn "  TinyPNG skip — HTTP #{res.code}: #{res.body[0, 200]}"
    return
  end

  shrunk_url = res["Location"] || JSON.parse(res.body)["output"]["url"]
  uri2 = URI(shrunk_url)
  Net::HTTP.start(uri2.hostname, uri2.port, use_ssl: true) do |http|
    http.request(Net::HTTP::Get.new(uri2)) do |r|
      File.open(path, "wb") { |f| r.read_body { |chunk| f.write(chunk) } }
    end
  end
end

# ---- main ---------------------------------------------------------------
targets = ARGV.empty? || ARGV == ["all"] ? SHOT_LIST.keys : ARGV
targets.each do |key|
  shot = SHOT_LIST[key]
  unless shot
    warn "Unknown shot: #{key}. Known: #{SHOT_LIST.keys.join(', ')}"
    next
  end

  out = PHOTOS_DIR.join("#{key}.png")
  if File.exist?(out)
    puts "✓ #{key} already exists, skipping (#{File.size(out)} bytes)"
    next
  end

  puts "→ #{key}: submitting Hedra job (#{shot[:resolution]} #{shot[:aspect]})…"
  result = submit_generation(**shot)
  gen_id   = result["id"]
  asset_id = result["asset_id"]
  abort "Missing id/asset_id in response: #{result.inspect}" unless gen_id && asset_id

  puts "  polling generation #{gen_id} (eta ~#{result['eta_sec']}s)…"
  poll_until_complete(gen_id)

  puts "  resolving asset URL for #{asset_id}…"
  asset_url = fetch_asset_url(asset_id)

  puts "  downloading from Hedra…"
  download(asset_url, out)
  puts "  pre-tinify size: #{File.size(out)} bytes"

  puts "  compressing via TinyPNG…"
  tinify_compress!(out)
  puts "✓ #{key} → #{out} (#{File.size(out)} bytes)"
end

puts "Done."
