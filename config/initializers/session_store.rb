session_options = {
  key: '_skookoo_session',
  redis: {
    db: 0,
    expire_after: 120.minutes,
    host: 'localhost',
    port: 6379
  }
}

# In production (HTTPS): allow extension iframe to receive session (cross-site)
# In development (HTTP): use defaults so login works; extension will show "log in" when used from other sites
if Rails.env.production?
  session_options[:same_site] = :none
  session_options[:secure] = true
end

Rails.application.config.session_store :redis_session_store, **session_options

