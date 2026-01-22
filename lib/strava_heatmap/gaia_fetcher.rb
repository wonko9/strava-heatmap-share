# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module StravaHeatmap
  # Fetches area bounds from Gaia GPS URLs
  class GaiaFetcher
    GAIA_API_BASE = "https://www.gaiagps.com/api/objects/area"

    attr_reader :min_lat, :max_lat, :min_lng, :max_lng, :name

    def initialize(url)
      @url = url
      @min_lat = Float::INFINITY
      @max_lat = -Float::INFINITY
      @min_lng = Float::INFINITY
      @max_lng = -Float::INFINITY
      @name = nil

      fetch_and_parse!
    end

    # Returns coordinates in NW/SE format for the CLI
    # @return [Array<Float>] [nw_lat, nw_lng, se_lat, se_lng]
    def bounds
      [max_lat, min_lng, min_lat, max_lng]
    end

    # Check if any coordinates were found
    def valid?
      @min_lat != Float::INFINITY
    end

    private

    def fetch_and_parse!
      area_id = extract_area_id(@url)
      raise Error, "Could not find areaId in URL: #{@url}" unless area_id

      api_url = "#{GAIA_API_BASE}/#{area_id}/"
      response = fetch_url(api_url)

      raise Error, "Failed to fetch area from Gaia API" unless response.is_a?(Net::HTTPSuccess)

      parse_geojson(response.body)
    end

    def extract_area_id(url)
      # Extract areaId from URL like:
      # https://www.gaiagps.com/map/?loc=11.2/-118.9958/37.5906&pubLink=xxx&areaId=eb57e93a-...
      uri = URI.parse(url)
      params = URI.decode_www_form(uri.query || "").to_h
      params["areaId"]
    rescue URI::InvalidURIError
      nil
    end

    def fetch_url(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request["User-Agent"] = "StravaHeatmap/#{VERSION}"

      http.request(request)
    end

    def parse_geojson(json_str)
      data = JSON.parse(json_str)

      feature = data["features"]&.first
      raise Error, "No features found in Gaia response" unless feature

      @name = feature.dig("properties", "title")

      geometry = feature["geometry"]
      raise Error, "No geometry found in Gaia response" unless geometry

      coordinates = case geometry["type"]
                    when "Polygon"
                      geometry["coordinates"].first
                    when "LineString"
                      geometry["coordinates"]
                    when "Point"
                      [geometry["coordinates"]]
                    else
                      raise Error, "Unsupported geometry type: #{geometry['type']}"
                    end

      coordinates.each do |coord|
        lng, lat = coord[0], coord[1]
        update_bounds(lat, lng)
      end

      raise Error, "No valid coordinates found in Gaia area" unless valid?
    end

    def update_bounds(lat, lng)
      return if lat.nil? || lng.nil?

      @min_lat = lat if lat < @min_lat
      @max_lat = lat if lat > @max_lat
      @min_lng = lng if lng < @min_lng
      @max_lng = lng if lng > @max_lng
    end
  end
end
