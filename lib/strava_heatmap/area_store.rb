# frozen_string_literal: true

require "json"
require "aws-sdk-s3"

module StravaHeatmap
  # Stores and retrieves saved area metadata from S3
  class AreaStore
    METADATA_KEY = "metadata/areas.json"

    attr_reader :bucket, :region

    def initialize(bucket: nil, region: nil)
      @bucket = bucket || ENV["AWS_S3_BUCKET"]
      @region = region || ENV["AWS_REGION"] || "us-west-2"
      @client = Aws::S3::Client.new(region: @region)
    end

    # List all saved areas
    # @return [Array<Hash>] Array of area metadata
    def list
      data = load_data
      data["areas"] || []
    end

    # Get a specific area by name
    # @param name [String] Area name
    # @return [Hash, nil] Area metadata or nil if not found
    def get(name)
      list.find { |a| a["name"].downcase == name.downcase }
    end

    # Save a new area
    # @param name [String] Area name
    # @param bounds [Hash] { nw_lat:, nw_lng:, se_lat:, se_lng: }
    # @param options [Hash] Additional metadata (activity, color, zoom levels, etc.)
    def save(name, bounds, options = {})
      data = load_data
      data["areas"] ||= []

      # Remove existing area with same name
      data["areas"].reject! { |a| a["name"].downcase == name.downcase }

      # Add new area
      data["areas"] << {
        "name" => name,
        "nw_lat" => bounds[:nw_lat],
        "nw_lng" => bounds[:nw_lng],
        "se_lat" => bounds[:se_lat],
        "se_lng" => bounds[:se_lng],
        "activity" => options[:activity],
        "color" => options[:color],
        "min_zoom" => options[:min_zoom],
        "max_zoom" => options[:max_zoom],
        "created_at" => Time.now.iso8601,
        "source" => options[:source] # e.g., "gaia", "gpx", "manual"
      }

      save_data(data)
    end

    # Delete an area by name
    # @param name [String] Area name
    # @return [Boolean] true if deleted, false if not found
    def delete(name)
      data = load_data
      original_count = data["areas"]&.length || 0
      data["areas"]&.reject! { |a| a["name"].downcase == name.downcase }

      if data["areas"]&.length != original_count
        save_data(data)
        true
      else
        false
      end
    end

    private

    def load_data
      response = @client.get_object(bucket: bucket, key: METADATA_KEY)
      JSON.parse(response.body.read)
    rescue Aws::S3::Errors::NoSuchKey
      { "areas" => [] }
    end

    def save_data(data)
      @client.put_object(
        bucket: bucket,
        key: METADATA_KEY,
        body: JSON.pretty_generate(data),
        content_type: "application/json"
      )
    end
  end
end
