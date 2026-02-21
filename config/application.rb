require_relative "boot"

require "rails/all"
require_relative "../lib/extension_frame_middleware"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Skookoo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.active_storage.variant_processor = :vips # sudo apt install libvips libvips-dev
    # config.active_storage.resolve_model_to_route = :rails_storage_proxy
    config.active_storage.resolve_model_to_route = :rails_storage_redirect

    # Allow /extension_modal to be embedded in iframes (Chrome extension)
    config.middleware.use ExtensionFrameMiddleware
  end
end
