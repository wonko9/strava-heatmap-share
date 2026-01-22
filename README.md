# Strava Heatmap Downloader

CLI tool to download Strava heatmap tiles for a geographic region and upload them to S3 for use as a custom layer in CalTopo or Gaia GPS.

## Installation

```bash
git clone <repo>
cd strava_heatmap_share
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
2. Go to the [Global Heatmap](https://www.strava.com/maps/global-heatmap)
3. Open browser dev tools (F12)
4. Go to **Application** > **Cookies** > **https://www.strava.com**
5. Find and copy these three cookie values:
   - `CloudFront-Key-Pair-Id`
   - `CloudFront-Policy`
   - `CloudFront-Signature`
6. Format them as a single string:
   ```
   CloudFront-Key-Pair-Id=XXX; CloudFront-Policy=XXX; CloudFront-Signature=XXX
   ```
7. Set this as `STRAVA_COOKIE` in your `.env` file

**Note:** These cookies expire after ~2 weeks. You'll need to refresh them periodically.

## Usage

```bash
bin/strava_heatmap [options] NW_LAT,NW_LNG SE_LAT,SE_LNG
```

### Arguments

- `NW_LAT,NW_LNG` - Northwest corner coordinates (e.g., `39.5,-120.5`)
- `SE_LAT,SE_LNG` - Southeast corner coordinates (e.g., `38.5,-119.5`)

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-a, --activity` | Activity type: all, ride, run, water, winter | winter |
| `-c, --color` | Heatmap color: hot, mobileblue, gray, bluered, purple, orange | hot |
| `-z, --min-zoom` | Minimum zoom level | 8 |
| `-Z, --max-zoom` | Maximum zoom level | 15 |
| `-p, --prefix` | S3 key prefix | tiles |
| `-n, --dry-run` | Show tile count without downloading | - |
| `-h, --help` | Show help | - |
| `-v, --version` | Show version | - |

### Examples

Download winter activity heatmap for Lake Tahoe area:

```bash
bin/strava_heatmap 39.5,-120.5 38.8,-119.8
```

Download cycling heatmap with orange color:

```bash
bin/strava_heatmap -a ride -c orange 39.5,-120.5 38.8,-119.8
```

Preview tile count without downloading:

```bash
bin/strava_heatmap --dry-run 39.5,-120.5 38.8,-119.8
```

## Using in CalTopo / Gaia GPS

After uploading tiles, the tool outputs a URL template like:

```
https://your-bucket.s3.us-west-2.amazonaws.com/tiles/winter/hot/{Z}/{X}/{Y}.png
```

### CalTopo

1. Click **Add New Layer** > **Custom Source**
2. Paste the URL template
3. Set layer type to **Tile**
4. Name it (e.g., "Strava Winter Heatmap")

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

## License

MIT
