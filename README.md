# TRMNL SF Muni Departures

A [TRMNL](https://usetrmnl.com) e-ink display plugin that shows real-time SF Muni departure times. Configure up to 10 route/stop/direction combinations and see the next departures for each on your TRMNL device.

Powered by the [511.org](https://511.org) real-time transit API.

## How It Works

```
TRMNL Device  →  TRMNL Cloud  →  This Server  →  511.org API
              ←               ←               ←
```

TRMNL Cloud polls your server every ~15 minutes. The server fetches real-time departure data from 511.org, filters it to your configured routes, and returns formatted JSON. TRMNL merges it into the Liquid template and renders it on the e-ink display.

The server deduplicates API calls — if you want routes 6 and 43 at the same stop, that's 1 API call, not 2.

## Setup

### 1. Get a 511.org API Key

1. Go to [511.org/open-data/token](https://511.org/open-data/token)
2. Sign up and get your API token

### 2. Find Your Stop IDs

Stop IDs are direction-specific. To find them:

1. Visit the [511.org GTFS data](https://511.org/open-data/transit) page
2. Or use the 511 API directly:
   ```
   https://api.511.org/transit/stops?api_key=YOUR_KEY&operator_id=SF&format=json
   ```
3. Find the stop codes for your desired stops and directions

### 3. Configure MUNI_STOPS

The `MUNI_STOPS` environment variable defines which routes/stops/directions to display.

**Format:** `route:stop_id:direction_label` separated by semicolons

**Examples:**
```bash
# Single route
MUNI_STOPS="6:15726:Downtown"

# Multiple routes at the same stop
MUNI_STOPS="6:15726:Downtown;43:15726:Downtown"

# Multiple stops and directions
MUNI_STOPS="6:15726:Downtown;6:15727:The Haight;43:15726:Downtown;43:15727:Masonic"
```

### 4. Run Locally

```bash
cp .env.example .env
# Edit .env with your API key and stop config

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
   - `MUNI_STOPS` — your route/stop/direction config
   - `MAX_DEPARTURES` — departures per combo (default: 3)
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
| `MUNI_STOPS` | Yes | — | Route/stop/direction config string |
| `MAX_DEPARTURES` | No | `3` | Max departures shown per route |

## Development

```bash
bundle install
bundle exec rspec        # Run tests
bundle exec rackup       # Start local server
```

## License

MIT
