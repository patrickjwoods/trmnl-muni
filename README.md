# TRMNL SF Muni Departures

A [TRMNL](https://usetrmnl.com) e-ink display plugin that shows real-time SF Muni departure times. Configure your stop IDs and see all upcoming departures grouped by line on your TRMNL device.

Powered by the [511.org](https://511.org) real-time transit API.

## How It Works

```
TRMNL Device  →  TRMNL Cloud  →  This Server  →  511.org API
              ←               ←               ←
```

TRMNL Cloud polls your server every ~15 minutes. The server fetches real-time departure data from 511.org for each configured stop, groups departures by line, and returns formatted JSON. TRMNL merges it into the Liquid template and renders it on the e-ink display.

## Setup

### 1. Get a 511.org API Key

1. Go to [511.org/open-data/token](https://511.org/open-data/token)
2. Sign up and get your API token

### 2. Find Your Stop IDs

Each physical stop has a unique numeric ID. To find yours:

1. Visit the [511.org GTFS data](https://511.org/open-data/transit) page
2. Or use the 511 API directly:
   ```
   https://api.511.org/transit/stops?api_key=YOUR_KEY&operator_id=SF&format=json
   ```
3. Find the stop codes for your desired stops

### 3. Configure MUNI_STOPS

The `MUNI_STOPS` environment variable is a semicolon-separated list of stop IDs.

**Examples:**
```bash
# Single stop
MUNI_STOPS="15726"

# Multiple stops
MUNI_STOPS="15726;15727"

# Three stops
MUNI_STOPS="15002;15715;15714"
```

No need to specify routes or directions — the API returns all lines serving each stop, and departures are automatically grouped by line.

### 4. Run Locally

```bash
cp .env.example .env
# Edit .env with your API key and stop IDs

bundle install
bundle exec rackup
```

Visit:
- `http://localhost:9292/preview` — HTML preview of the display
- `http://localhost:9292/departures.json` — JSON endpoint
- `http://localhost:9292/health` — Health check

### 5. Deploy to Render.com

1. Push this repo to GitHub
2. Create a new Web Service on [Render.com](https://render.com)
3. Connect your GitHub repo
4. Set environment variables:
   - `API_KEY_511` — your 511.org API key
   - `MUNI_STOPS` — semicolon-separated stop IDs
   - `MAX_DEPARTURES` — departures per line (default: 3)
5. Deploy and verify `/health` returns 200

### 6. Configure TRMNL

1. In your [TRMNL dashboard](https://usetrmnl.com), create a **Private Plugin**
2. Set strategy to **Polling**
3. Set the polling URL to your Render deployment URL + `/departures.json`
4. Open the **Markup Editor** and paste the contents of `views/markup/full.liquid`
5. Save and use **Force Refresh** to test

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `API_KEY_511` | Yes | — | Your 511.org API key |
| `MUNI_STOPS` | Yes | — | Semicolon-separated stop IDs |
| `MAX_DEPARTURES` | No | `3` | Max departures shown per line |

## Development

```bash
bundle install
bundle exec rspec        # Run tests
bundle exec rackup       # Start local server
```

## License

MIT
