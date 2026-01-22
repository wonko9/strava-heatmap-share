# frozen_string_literal: true

module StravaHeatmap
  # Handles conversion between lat/long coordinates and tile x/y coordinates
  # using Web Mercator projection (EPSG:3857)
  class TileCalculator
    # Convert lat/long to tile x,y at a given zoom level
    # @param lat [Float] Latitude in degrees
    # @param lng [Float] Longitude in degrees
    # @param zoom [Integer] Zoom level
    # @return [Array<Integer>] [x, y] tile coordinates
    def self.lat_lng_to_tile(lat, lng, zoom)
      n = 2**zoom
      x = ((lng + 180.0) / 360.0 * n).floor
      lat_rad = lat * Math::PI / 180.0
      y = ((1.0 - Math.log(Math.tan(lat_rad) + 1.0 / Math.cos(lat_rad)) / Math::PI) / 2.0 * n).floor
      [x, y]
    end

    # Convert tile x,y,z to lat/lng bounds
    # @param x [Integer] Tile x coordinate
    # @param y [Integer] Tile y coordinate
    # @param zoom [Integer] Zoom level
    # @return [Hash] { north:, south:, east:, west: } bounds in degrees
    def self.tile_to_bounds(x, y, zoom)
      n = 2**zoom
      west = x.to_f / n * 360.0 - 180.0
      east = (x + 1).to_f / n * 360.0 - 180.0
      north = Math.atan(Math.sinh(Math::PI * (1 - 2 * y.to_f / n))) * 180.0 / Math::PI
      south = Math.atan(Math.sinh(Math::PI * (1 - 2 * (y + 1).to_f / n))) * 180.0 / Math::PI
      { north: north, south: south, east: east, west: west }
    end

    # Get all tiles needed to cover a bounding box at a specific zoom level
    # @param nw_lat [Float] Northwest corner latitude
    # @param nw_lng [Float] Northwest corner longitude
    # @param se_lat [Float] Southeast corner latitude
    # @param se_lng [Float] Southeast corner longitude
    # @param zoom [Integer] Zoom level
    # @return [Array<Hash>] Array of tile hashes with :x, :y, :z keys
    def self.tiles_for_bounds(nw_lat, nw_lng, se_lat, se_lng, zoom)
      nw_tile = lat_lng_to_tile(nw_lat, nw_lng, zoom)
      se_tile = lat_lng_to_tile(se_lat, se_lng, zoom)

      tiles = []
      (nw_tile[0]..se_tile[0]).each do |x|
        (nw_tile[1]..se_tile[1]).each do |y|
          tiles << { x: x, y: y, z: zoom }
        end
      end
      tiles
    end

    # Get all tiles for a bounding box across a range of zoom levels
    # @param nw_lat [Float] Northwest corner latitude
    # @param nw_lng [Float] Northwest corner longitude
    # @param se_lat [Float] Southeast corner latitude
    # @param se_lng [Float] Southeast corner longitude
    # @param min_zoom [Integer] Minimum zoom level
    # @param max_zoom [Integer] Maximum zoom level
    # @return [Array<Hash>] Array of tile hashes with :x, :y, :z keys
    def self.tiles_for_bounds_range(nw_lat, nw_lng, se_lat, se_lng, min_zoom, max_zoom)
      tiles = []
      (min_zoom..max_zoom).each do |zoom|
        tiles.concat(tiles_for_bounds(nw_lat, nw_lng, se_lat, se_lng, zoom))
      end
      tiles
    end

    # Count total tiles for a bounding box across zoom range
    # Useful for progress estimation
    def self.count_tiles(nw_lat, nw_lng, se_lat, se_lng, min_zoom, max_zoom)
      count = 0
      (min_zoom..max_zoom).each do |zoom|
        nw_tile = lat_lng_to_tile(nw_lat, nw_lng, zoom)
        se_tile = lat_lng_to_tile(se_lat, se_lng, zoom)
        width = se_tile[0] - nw_tile[0] + 1
        height = se_tile[1] - nw_tile[1] + 1
        count += width * height
      end
      count
    end
  end
end
