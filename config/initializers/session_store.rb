# Allow extension iframe to receive session when loaded from other sites (cross-site)
# Chrome treats localhost as secure, so secure: true works in dev
cookie_options = {
  key: '_skookoo_session',
  same_site: :none,
  secure: true
}

if Rails.env.production?
  Rails.application.config.session_store :redis_session_store,
    **cookie_options,
    redis: {
      db: 0,
      expire_after: 120.minutes,
      host: ENV.fetch("REDIS_HOST", "localhost"),
      port: ENV.fetch("REDIS_PORT", "6379").to_i
    }
else
  # Use CookieStore in dev: simpler, reliable with same_site/secure on localhost
  Rails.application.config.session_store :cookie_store, **cookie_options
end

