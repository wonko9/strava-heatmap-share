# frozen_string_literal: true

require "rexml/document"

module StravaHeatmap
  # Parses GPX files to extract bounding box coordinates
  class GpxParser
    attr_reader :min_lat, :max_lat, :min_lng, :max_lng

    def initialize(file_path)
      @file_path = file_path
      @min_lat = Float::INFINITY
      @max_lat = -Float::INFINITY
      @min_lng = Float::INFINITY
      @max_lng = -Float::INFINITY

      parse!
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

    def parse!
      raise Error, "GPX file not found: #{@file_path}" unless File.exist?(@file_path)

      content = File.read(@file_path)
      doc = REXML::Document.new(content)

      # Extract coordinates from various GPX elements
      extract_from_waypoints(doc)
      extract_from_tracks(doc)
      extract_from_routes(doc)
      extract_from_bounds(doc)

      raise Error, "No coordinates found in GPX file" unless valid?
    end

    def extract_from_waypoints(doc)
      doc.elements.each("//wpt") do |wpt|
        update_bounds(wpt.attributes["lat"], wpt.attributes["lon"])
      end
    end

    def extract_from_tracks(doc)
      doc.elements.each("//trkpt") do |trkpt|
        update_bounds(trkpt.attributes["lat"], trkpt.attributes["lon"])
      end
    end

    def extract_from_routes(doc)
      doc.elements.each("//rtept") do |rtept|
        update_bounds(rtept.attributes["lat"], rtept.attributes["lon"])
      end
    end

    def extract_from_bounds(doc)
      # Gaia exports areas with metadata bounds
      doc.elements.each("//bounds") do |bounds|
        update_bounds(bounds.attributes["minlat"], bounds.attributes["minlon"])
        update_bounds(bounds.attributes["maxlat"], bounds.attributes["maxlon"])
      end
    end

    def update_bounds(lat, lng)
      return if lat.nil? || lng.nil?

      lat = lat.to_f
      lng = lng.to_f

      @min_lat = lat if lat < @min_lat
      @max_lat = lat if lat > @max_lat
      @min_lng = lng if lng < @min_lng
      @max_lng = lng if lng > @max_lng
    end
  end
end
