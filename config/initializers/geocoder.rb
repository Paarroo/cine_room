Geocoder.configure(
  # Use OpenCage for much better accuracy than Nominatim
  lookup: :opencagedata,
  
  # OpenCage API key (get free key at opencagedata.com - 2,500 requests/day free)
  api_key: ENV['OPENCAGE_API_KEY'],
  
  # Basic options
  timeout: 15,                 # increased timeout for international geocoding
  ip_lookup: :ipinfo_io,       # name of IP address geocoding service (symbol)
  use_https: true,             # use HTTPS for lookup requests
  http_proxy: nil,             # HTTP proxy server (user:pass@host:port)
  https_proxy: nil,            # HTTPS proxy server (user:pass@host:port)
  cache: Rails.cache,          # use Rails cache for geocoding results

  # Exceptions that should not be rescued by default
  always_raise: [],

  # Calculation options
  units: :km,                  # :km for kilometers or :mi for miles
  distances: :spherical,       # :spherical for better accuracy

  # Cache configuration
  cache_options: {
    expiration: 1.week,        # cache geocoding results for 1 week
    prefix: 'cineroom_geocoder:'
  },

  # Rate limiting and international support
  http_headers: {
    "User-Agent" => "CineRoom Cinema App",
    "Accept-Language" => "en,fr;q=0.9,es;q=0.8,de;q=0.7"
  },

  # OpenCage specific options for better international results
  opencagedata: {
    language: "en",              # Primary language for results
    countrycode: nil,           # Allow worldwide geocoding (no country restriction)
    bounds: nil,                # No geographic bounds restriction
    limit: 3,                   # Get up to 3 results for better matching
    min_confidence: 3,          # Minimum confidence (1-10 scale, lower = more permissive)
    no_annotations: false,      # Include annotations (timezone, currency, etc.)
    no_dedupe: false,          # Allow deduplication of similar results
    no_record: false,          # Allow request recording for debugging
    pretty: false,             # Compact response format for efficiency
    roadinfo: true,            # Include road information when available
    abbrv: false               # Don't abbreviate results (full names)
  }
)