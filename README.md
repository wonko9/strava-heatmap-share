# Strava Heatmap Downloader

CLI tool to download Strava heatmap tiles for a geographic region and upload them to S3 for use as a custom layer in CalTopo or Gaia GPS.

## Installation

```bash
git clone https://github.com/wonko9/strava-heatmap-share.git
cd strava-heatmap-share
bundle install
```

## Configuration

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

### AWS Credentials

Set up your AWS credentials with S3 write access:

- `AWS_REGION` - AWS region (default: us-west-2)
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
- `AWS_S3_BUCKET` - S3 bucket name for storing tiles

### Strava Cookie

To get your Strava authentication cookie:

1. Log into [Strava](https://www.strava.com)
2. Go to your [Personal Heatmap](https://www.strava.com/maps/personal-heatmap)
3. Open browser dev tools (F12) > **Network** tab
4. Filter by `personal-heatmaps-external`
5. Click on any tile request (`.png` file)
6. Copy the full **Cookie** header from Request Headers
7. Set this as `STRAVA_COOKIE` in your `.env` file

**Note:** These cookies expire after ~2 weeks. Use `bin/check_expiry` to check status.

## Main Command

```bash
bin/strava_heatmap [options] [NW_LAT,NW_LNG SE_LAT,SE_LNG]
```

### Coordinate Input Methods

You can specify the region in several ways:

```bash
# Direct coordinates (NW corner to SE corner)
bin/strava_heatmap 39.5,-120.5 38.8,-119.8

# From a GPX file (e.g., Gaia area export)
bin/strava_heatmap --gpx myarea.gpx

# From a Gaia GPS area URL
bin/strava_heatmap --gaia-url "https://www.gaiagps.com/map/?..."

# From a saved area
bin/strava_heatmap --area tahoe
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-g, --gpx FILE` | GPX file to extract bounds from | - |
| `-u, --gaia-url URL` | Gaia GPS area URL to extract bounds from | - |
| `-a, --activity TYPE` | Activity type (see below) | BackcountrySki |
| `-c, --color COLOR` | Heatmap color: hot, mobileblue, gray, bluered, purple, orange | hot |
| `-z, --min-zoom ZOOM` | Minimum zoom level | 8 |
| `-Z, --max-zoom ZOOM` | Maximum zoom level | 15 |
| `-p, --prefix PREFIX` | S3 key prefix | tiles |
| `-s, --skip-existing` | Skip tiles that already exist in S3 | - |
| `-n, --dry-run` | Show tile count without downloading | - |
| `-k, --kml FILE` | Generate KML file for Google Earth | - |
| `-h, --help` | Show help | - |
| `-v, --version` | Show version | - |

### Activity Types

Supported activity types include:
- `BackcountrySki`, `NordicSki`, `AlpineSki`, `Snowboard`, `Snowshoe`
- `Ride`, `Run`, `Walk`, `Hike`
- `Swim`, `Kayaking`
- And other Strava activity types

### Area Management

Save and reuse frequently-used regions:

```bash
# Save an area for later
bin/strava_heatmap --save-area tahoe 39.5,-120.5 38.8,-119.8

# Save without downloading (just store the coordinates)
bin/strava_heatmap --save-only tahoe 39.5,-120.5 38.8,-119.8

# List all saved areas
bin/strava_heatmap --list-areas

# Use a saved area
bin/strava_heatmap --area tahoe

# Delete a saved area
bin/strava_heatmap --delete-area tahoe
```

### Examples

Download backcountry ski heatmap for Lake Tahoe area:

```bash
bin/strava_heatmap 39.5,-120.5 38.8,-119.8
```

Download cycling heatmap with orange color:

```bash
bin/strava_heatmap -a Ride -c orange 39.5,-120.5 38.8,-119.8
```

Preview tile count without downloading:

```bash
bin/strava_heatmap --dry-run 39.5,-120.5 38.8,-119.8
```

Generate a KML file for Google Earth:

```bash
bin/strava_heatmap --kml output.kml --area tahoe
```

## Utility Scripts

### `bin/test_cookie`

Test that your Strava cookie authentication is working:

```bash
bin/test_cookie
```

### `bin/check_expiry`

Check when your Strava cookie expires:

```bash
bin/check_expiry
```

### `bin/check_s3`

Verify your AWS S3 configuration and credentials:

```bash
bin/check_s3
```

### `bin/find_bucket`

Find which AWS region your S3 bucket is in:

```bash
bin/find_bucket
```

### `bin/debug_url`

Debug URL encoding for CloudFront authentication:

```bash
bin/debug_url
```

## Using Tiles in CalTopo / Gaia GPS

After uploading tiles, the tool outputs a URL template like:

```
https://your-bucket.s3.us-west-2.amazonaws.com/tiles/BackcountrySki/hot/{Z}/{X}/{Y}.png
```

### CalTopo

1. Click **Add New Layer** > **Custom Source**
2. Paste the URL template
3. Set layer type to **Tile**
4. Name it (e.g., "Strava Backcountry Ski Heatmap")

### Gaia GPS

1. Go to **Settings** > **Custom Map Sources**
2. Add new source
3. Paste the URL template
4. Set format to **XYZ Tiles**

## S3 Bucket Configuration

Your S3 bucket needs to be configured for public read access to serve tiles. Example bucket policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::your-bucket-name/tiles/*"
    }
  ]
}
```

## Troubleshooting

### Cookie expired
Run `bin/check_expiry` to see the expiration status. If expired, get a fresh cookie from your browser.

### 403 Forbidden errors
Your cookie may be invalid or expired. Run `bin/test_cookie` to verify authentication.

### S3 access denied
Check your AWS credentials with `bin/check_s3`. Ensure your IAM user has s3:PutObject and s3:GetObject permissions.

### Wrong S3 region
If you get region errors, run `bin/find_bucket` to find the correct region for your bucket.

## License

MIT
