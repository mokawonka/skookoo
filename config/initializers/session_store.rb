Rails.application.config.session_store :redis_session_store,
  key: '_skookoo_session',
  redis: {
    db: 0,
    expire_after: 120.minutes,
    host: 'localhost',
    port: 6379
  },
  # Required for Chrome extension iframe: cookie must be sent in cross-site context
  same_site: :none,
  secure: true

