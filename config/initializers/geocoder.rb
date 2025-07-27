Geocoder.configure(
  # Geocoding options
  timeout: 10,                  # increased timeout for production stability
  lookup: :nominatim,          # name of geocoding service (symbol)
  ip_lookup: :ipinfo_io,       # name of IP address geocoding service (symbol)
  language: :fr,               # ISO-639 language code
  use_https: true,             # use HTTPS for lookup requests? (if supported)
  http_proxy: nil,             # HTTP proxy server (user:pass@host:port)
  https_proxy: nil,            # HTTPS proxy server (user:pass@host:port)
  api_key: nil,                # API key for geocoding service
  cache: Rails.cache,          # use Rails cache for geocoding results

  # Exceptions that should not be rescued by default
  # (if you want to implement custom error handling);
  # supports SocketError and Timeout::Error
  always_raise: [],

  # Calculation options
  units: :km,                  # :km for kilometers or :mi for miles
  distances: :linear,          # :spherical or :linear

  # Cache configuration
  cache_options: {
    expiration: 1.week,        # cache geocoding results for 1 week
    prefix: 'cineroom_geocoder:'
  },

  # Rate limiting configuration
  http_headers: {
    "User-Agent" => "CineRoom Cinema App"
  }
)