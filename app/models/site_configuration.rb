class SiteConfiguration
  PROPERTIES = [
    :site_id,
    :modules,
    :logo,
    :demo,
    :password_protection_username,
    :password_protection_password,
    :google_analytics_id,
    :head_markup,
    :foot_markup,
    :links_markup,
    :available_locales,
    :default_locale,
    :privacy_page_id,
    :populate_data_api_token,
    :home_page,
    :home_page_item_id,
    :raw_configuration_variables,
    :auth_modules,
    :admin_auth_modules,
    :engine_overrides
  ].freeze

  DEFAULT_LOGO_PATH = "sites/logo-default.png"
  MODULES_WITH_NOTIFICATONS = %w(GobiertoPeople GobiertoBudgetConsultations).freeze
  MODULES_WITH_COLLECTIONS = %w(GobiertoData).freeze

  attr_accessor *PROPERTIES

  alias :site_modules :modules

  def initialize(configuration_params)
    return unless configuration_params.is_a?(Hash)

    PROPERTIES.each do |property|
      instance_variable_set("@#{property}", configuration_params[property.to_s])
    end
  end

  def modules
    return [] unless @modules.present?

    @modules.select { |site_module| SITE_MODULES.include?(site_module) }
  end

  def modules_with_frontend_enabled
    modules.reject do |site_module|
      GobiertoModuleSettings.find_by(site_id: site_id, module_name: site_module)&.frontend_disabled
    end
  end

  def available_module?(site_module)
    modules.include?(site_module)
  end

  def auth_modules
    return DEFAULT_MISSING_MODULES.reject(&:admin).map(&:name) if @auth_modules.nil?

    @auth_modules & AUTH_MODULES.reject(&:admin).map(&:name)
  end

  def admin_auth_modules
    return DEFAULT_MISSING_MODULES.select(&:admin) if @admin_auth_modules.blank?

    @admin_auth_modules & AUTH_MODULES.select(&:admin).map(&:name)
  end

  def auth_modules_data
    AUTH_MODULES.select { |mod| auth_modules.include?(mod.name) }
  end

  def admin_auth_modules_data
    AUTH_MODULES.select { |mod| admin_auth_modules.include?(mod.name) }
  end

  def engine_overrides
    @engine_overrides || []
  end

  def logo_with_fallback
    @logo || DEFAULT_LOGO_PATH
  end

  def available_locales
    return I18n.available_locales if @available_locales.nil? || @available_locales.empty?

    Array(default_locale).concat(@available_locales.select{ |l| l.present? }.map(&:to_s)).uniq
  end

  def default_locale
    @default_locale || I18n.default_locale
  end

  def privacy_page
    @privacy_page ||= GobiertoCms::Page.find_by(site_id: site_id, id: privacy_page_id) if site_id.present? && privacy_page_id.present?
  end

  def privacy_page?
    privacy_page.present?
  end

  def modules_with_notifications
    modules_with_frontend_enabled & MODULES_WITH_NOTIFICATONS
  end

  def modules_with_collections
    modules & MODULES_WITH_COLLECTIONS
  end

  def default_modules
    [ 'GobiertoCms', 'GobiertoCalendars', 'GobiertoAttachments' ]
  end

  def configuration_variables
    if raw_configuration_variables.blank?
      {}
    else
      YAML.load(raw_configuration_variables)
    end
  rescue Psych::SyntaxError
    {}
  end

  # Define question mark instance methods for each property.
  # i.e. `#demo?`.
  #
  PROPERTIES.each do |property|
    define_method "#{property}?" do
      send(property).present?
    end
  end

  # Define instance methods to check if a Site Module has been enabled.
  # i.e. `#gobierto_development_enabled?`.
  #
  SITE_MODULES.each do |site_module|
    define_method "#{site_module.underscore}_enabled?" do
      available_module?(site_module)
    end
  end
end
