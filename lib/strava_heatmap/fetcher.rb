# frozen_string_literal: true

require "down"
require "fileutils"
require "uri"

module StravaHeatmap
  # Handles fetching heatmap tiles from Strava's global heatmap
  class Fetcher
    TILE_SERVER = "https://content-a.strava.com"

    attr_reader :activity, :color, :cookie

    def initialize(activity: DEFAULT_ACTIVITY, color: DEFAULT_COLOR, cookie: nil, strava_id: nil)
      @activity = activity
      @color = color
      @cookie = cookie || ENV["STRAVA_COOKIE"]
      # strava_id no longer needed for global heatmap

      validate_config!
    end

    # Fetch a single tile and return the tempfile
    # @param tile [Hash] Tile with :x, :y, :z keys
    # @return [Tempfile] Downloaded tile image, or nil if tile is empty (404)
    def fetch_tile(tile)
      url = tile_url(tile)
      Down.download(url, headers: request_headers, max_size: 1 * 1024 * 1024)
    rescue Down::NotFound
      # 404 means no heatmap data for this tile - this is normal
      nil
    rescue Down::Error => e
      raise Error, "Failed to download tile z=#{tile[:z]} x=#{tile[:x]} y=#{tile[:y]}: #{e.message}"
    end

    # Build the URL for a specific tile
    # URL format: /identified/globalheat/sport_{activity}/{color}/{z}/{x}/{y}@2x.png?v=19
    # @param tile [Hash] Tile with :x, :y, :z keys
    # @return [String] Full tile URL
    def tile_url(tile)
      path = "/identified/globalheat/sport_#{activity}/#{color}/#{tile[:z]}/#{tile[:x]}/#{tile[:y]}@2x.png"
      "#{TILE_SERVER}#{path}?v=19"
    end

    private

    def request_headers
      {
        "Cookie" => cookie,
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        "Referer" => "https://www.strava.com/maps/global-heatmap"
      }
    end

    def validate_config!
      raise Error, "STRAVA_COOKIE environment variable is required" if cookie.nil? || cookie.empty?
      raise Error, "Invalid color: #{color}" unless VALID_COLORS.include?(color)
    end
  end
end
