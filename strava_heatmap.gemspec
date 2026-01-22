# frozen_string_literal: true

require_relative "lib/strava_heatmap/version"

Gem::Specification.new do |spec|
  spec.name = "strava_heatmap"
  spec.version = StravaHeatmap::VERSION
  spec.authors = [""]
  spec.email = [""]

  spec.summary = "Download Strava heatmap tiles and upload to S3"
  spec.description = "CLI tool to download Strava heatmap tiles for a geographic region and upload them to S3 for use in CalTopo/Gaia"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir["lib/**/*.rb", "bin/*", "README.md", "LICENSE"]
  spec.bindir = "bin"
  spec.executables = ["strava_heatmap"]
  spec.require_paths = ["lib"]

  spec.add_dependency "dotenv", "~> 3.0"
  spec.add_dependency "down", "~> 5.0"
  spec.add_dependency "aws-sdk-s3", "~> 1.0"
  spec.add_dependency "optparse"
end
