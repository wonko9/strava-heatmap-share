# frozen_string_literal: true

require "aws-sdk-s3"

module StravaHeatmap
  # Handles uploading tiles to S3 with CalTopo/Gaia-compatible paths
  class S3Uploader
    attr_reader :bucket, :region, :prefix, :activity, :color

    def initialize(bucket: nil, region: nil, prefix: "tiles", activity: DEFAULT_ACTIVITY, color: DEFAULT_COLOR)
      @bucket = bucket || ENV["AWS_S3_BUCKET"]
      @region = region || ENV["AWS_REGION"] || "us-west-2"
      @prefix = prefix
      @activity = activity
      @color = color

      validate_config!
    end

    # Upload a tile to S3
    # @param tile [Hash] Tile with :x, :y, :z keys
    # @param file [File, Tempfile] The tile image file
    # @return [String] The S3 object key
    def upload(tile, file)
      key = object_key(tile)
      client.put_object(
        bucket: bucket,
        key: key,
        body: file,
        content_type: "image/png",
        cache_control: "public, max-age=31536000"
      )
      key
    end

    # Check if a tile already exists in S3
    # @param tile [Hash] Tile with :x, :y, :z keys
    # @return [Boolean] true if tile exists
    def exists?(tile)
      key = object_key(tile)
      client.head_object(bucket: bucket, key: key)
      true
    rescue Aws::S3::Errors::NotFound
      false
    end

    # Generate the S3 object key for a tile
    # Format: {prefix}/{activity}/{color}/{z}/{x}/{y}.png
    # @param tile [Hash] Tile with :x, :y, :z keys
    # @return [String] S3 object key
    def object_key(tile)
      "#{prefix}/#{activity}/#{color}/#{tile[:z]}/#{tile[:x]}/#{tile[:y]}.png"
    end

    # Generate the public URL for accessing tiles
    # This is the URL template you paste into CalTopo/Gaia
    # @return [String] URL template with {Z}/{X}/{Y} placeholders
    def url_template
      "https://#{bucket}.s3.#{region}.amazonaws.com/#{prefix}/#{activity}/#{color}/{Z}/{X}/{Y}.png"
    end

    private

    def client
      @client ||= Aws::S3::Client.new(region: region)
    end

    def validate_config!
      raise Error, "AWS_S3_BUCKET environment variable is required" if bucket.nil? || bucket.empty?
    end
  end
end
