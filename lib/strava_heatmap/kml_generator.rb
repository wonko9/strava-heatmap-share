# frozen_string_literal: true

require "rexml/document"

module StravaHeatmap
  # Generates KML files with GroundOverlay elements for heatmap tiles
  class KmlGenerator
    attr_reader :activity, :color, :prefix, :bucket, :region

    def initialize(activity:, color:, prefix: "tiles", bucket: nil, region: nil)
      @activity = activity
      @color = color
      @prefix = prefix
      @bucket = bucket || ENV["AWS_S3_BUCKET"]
      @region = region || ENV["AWS_REGION"] || "us-west-2"
    end

    # Generate KML for tiles in a bounding box
    # @param nw_lat [Float] Northwest corner latitude
    # @param nw_lng [Float] Northwest corner longitude
    # @param se_lat [Float] Southeast corner latitude
    # @param se_lng [Float] Southeast corner longitude
    # @param min_zoom [Integer] Minimum zoom level
    # @param max_zoom [Integer] Maximum zoom level
    # @return [String] KML document as string
    def generate(nw_lat, nw_lng, se_lat, se_lng, min_zoom, max_zoom)
      tiles = TileCalculator.tiles_for_bounds_range(
        nw_lat, nw_lng, se_lat, se_lng,
        min_zoom, max_zoom
      )

      build_kml(tiles)
    end

    # Generate KML for a specific zoom level only
    def generate_for_zoom(nw_lat, nw_lng, se_lat, se_lng, zoom)
      tiles = TileCalculator.tiles_for_bounds(nw_lat, nw_lng, se_lat, se_lng, zoom)
      build_kml(tiles)
    end

    private

    def build_kml(tiles)
      doc = REXML::Document.new
      doc << REXML::XMLDecl.new("1.0", "UTF-8")

      kml = doc.add_element("kml", "xmlns" => "http://www.opengis.net/kml/2.2")
      document = kml.add_element("Document")
      document.add_element("name").text = "Strava Heatmap - #{activity}"
      document.add_element("description").text = "Strava global heatmap tiles for #{activity}"

      # Group tiles by zoom level into folders
      tiles_by_zoom = tiles.group_by { |t| t[:z] }

      tiles_by_zoom.keys.sort.each do |zoom|
        folder = document.add_element("Folder")
        folder.add_element("name").text = "Zoom #{zoom}"

        tiles_by_zoom[zoom].each do |tile|
          add_ground_overlay(folder, tile)
        end
      end

      output = +""
      formatter = REXML::Formatters::Pretty.new(2)
      formatter.compact = true
      formatter.write(doc, output)
      output
    end

    def add_ground_overlay(parent, tile)
      bounds = TileCalculator.tile_to_bounds(tile[:x], tile[:y], tile[:z])

      overlay = parent.add_element("GroundOverlay")
      overlay.add_element("name").text = "z#{tile[:z]}_x#{tile[:x]}_y#{tile[:y]}"

      icon = overlay.add_element("Icon")
      icon.add_element("href").text = tile_url(tile)

      lat_lon_box = overlay.add_element("LatLonBox")
      lat_lon_box.add_element("north").text = bounds[:north].to_s
      lat_lon_box.add_element("south").text = bounds[:south].to_s
      lat_lon_box.add_element("east").text = bounds[:east].to_s
      lat_lon_box.add_element("west").text = bounds[:west].to_s
    end

    def tile_url(tile)
      "https://#{bucket}.s3.#{region}.amazonaws.com/#{prefix}/#{activity}/#{color}/#{tile[:z]}/#{tile[:x]}/#{tile[:y]}.png"
    end
  end
end
