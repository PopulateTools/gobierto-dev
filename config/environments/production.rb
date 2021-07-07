# frozen_string_literal: true

Rails.application.configure do
  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = false

  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  if ENV["RAILS_SERVE_STATIC_FILES"].present?
    config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  end

  # Compress JavaScripts and CSS.
  # config.assets.js_compressor = Uglifier.new(harmony: true)
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = ENV.fetch("ASSETS_COMPILE") { "true" }

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  if ENV["GOBIERTO_FORCE_SSL"].present?
    config.force_ssl = ENV["GOBIERTO_FORCE_SSL"].present?
  end

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  config.log_tags = [:host, :request_id]

  if ENV["GOBIERTO_CACHE_TYPE"] == "mem_cache_store"
    config.cache_store = :mem_cache_store, ENV["GOBIERTO_CACHE_MEMCACHE_HOST"]
  end

  # Use a real queuing backend for Active Job (and separate queues per environment)
  config.active_job.queue_adapter = :sidekiq

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  config.action_mailer.default_url_options = { script_name: "" }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  # config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  app_host = ENV.fetch("HOST") { "gobierto.test" }

  config.action_mailer.default_url_options = {
    host: app_host,
    script_name: ""
  }
  config.action_mailer.asset_host = "http://#{app_host}"
  config.action_mailer.perform_deliveries = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.middleware.insert_before(0, Rack::Cors) do
    allow do
      origins "*"

      resource "/api/*",
        :headers => :any,
        :methods => [:get, :post, :delete, :put, :patch, :options, :head],
        :max_age => 0
    end
  end
end
