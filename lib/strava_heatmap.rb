# frozen_string_literal: true

require "dotenv"
Dotenv.load

require_relative "strava_heatmap/version"
require_relative "strava_heatmap/tile_calculator"
require_relative "strava_heatmap/fetcher"
require_relative "strava_heatmap/s3_uploader"
require_relative "strava_heatmap/gpx_parser"
require_relative "strava_heatmap/gaia_fetcher"
require_relative "strava_heatmap/kml_generator"
require_relative "strava_heatmap/area_store"

module StravaHeatmap
  class Error < StandardError; end

  # Activity types are Strava sport names (used as filter_type=sport_{activity})
  VALID_ACTIVITIES = %w[
    BackcountrySki NordicSki AlpineSki Snowboard Snowshoe
    Ride Run Walk Hike
    Swim Kayaking Rowing StandUpPaddling Surfing
    IceSkate
  ].freeze
  VALID_COLORS = %w[hot mobileblue gray bluered purple orange].freeze
  DEFAULT_ACTIVITY = "BackcountrySki"
  DEFAULT_COLOR = "hot"
  DEFAULT_MIN_ZOOM = 8
  DEFAULT_MAX_ZOOM = 15
end
