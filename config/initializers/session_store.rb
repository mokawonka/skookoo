# Session store config
if Rails.env.production?
  # Production (HTTPS): allow extension iframe to receive session from other sites
  Rails.application.config.session_store :redis_session_store,
    key: '_skookoo_session',
    same_site: :none,
    secure: true,
    redis: {
      db: 0,
      expire_after: 120.minutes,
      host: ENV.fetch("REDIS_HOST", "localhost"),
      port: ENV.fetch("REDIS_PORT", "6379").to_i
    }
else
  # Development: default cookies so login works.
  # Extension only gets session when used ON localhost (e.g. highlight on your Skookoo site).
  # When used on lemonde.fr etc., extension shows "log in" — test that in production.
  Rails.application.config.session_store :redis_session_store,
    key: '_skookoo_session',
    redis: {
      db: 0,
      expire_after: 120.minutes,
      host: 'localhost',
      port: 6379
    }
end

