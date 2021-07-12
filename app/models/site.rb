# frozen_string_literal: true

class Site < ApplicationRecord

  RESERVED_SUBDOMAINS = %w(presupuestos hosted).freeze

  has_many :activities

  # GobiertoAdmin integrations
  has_many :admin_sites, dependent: :destroy, class_name: "GobiertoAdmin::AdminSite"
  has_many :admins, through: :admin_sites, class_name: "GobiertoAdmin::Admin"
  has_many :census_imports, dependent: :destroy, class_name: "GobiertoAdmin::CensusImport"
  has_many :admin_groups, dependent: :destroy, class_name: "GobiertoAdmin::AdminGroup"

  # GobiertoCommon integration
  has_many :collections, dependent: :destroy, class_name: "GobiertoCommon::Collection"
  has_many :collection_items, as: :container, class_name: "GobiertoCommon::CollectionItem", dependent: :destroy

  has_many :content_blocks, dependent: :destroy, class_name: "GobiertoCommon::ContentBlock"
  has_many :custom_user_fields, dependent: :destroy, class_name: "GobiertoCommon::CustomUserField"

  has_many :vocabularies, dependent: :destroy, class_name: "GobiertoCommon::Vocabulary"
  has_many :terms, through: :vocabularies, class_name: "GobiertoCommon::Term"

  has_many :custom_fields, class_name: "GobiertoCommon::CustomField"
  has_many :custom_field_records, through: :custom_fields, class_name: "GobiertoCommon::CustomFieldRecord", source: :records

  has_many :pg_search_documents, class_name: "PgSearch::Document"

  # User integrations
  has_many :subscriptions, dependent: :destroy, class_name: "User::Subscription"
  has_many :notifications, dependent: :destroy, class_name: "User::Notification"
  has_many :users, dependent: :nullify

  # GobiertoBudgets integration
  has_many :custom_budget_lines_categories, dependent: :destroy, class_name: "GobiertoBudgets::Category"

  # GobiertoBudgetConsultations integration
  has_many :budget_consultations, dependent: :destroy, class_name: "GobiertoBudgetConsultations::Consultation"
  has_many :budget_consultation_responses, through: :budget_consultations, source: :consultation_responses, class_name: "GobiertoBudgetConsultations::ConsultationResponse"

  # GobiertoPeople integration
  has_many :people, dependent: :destroy, class_name: "GobiertoPeople::Person"
  has_many :person_posts, through: :people, source: :posts, class_name: "GobiertoPeople::PersonPost"
  has_many :person_statements, through: :people, source: :statements, class_name: "GobiertoPeople::PersonStatement"
  has_many :departments, dependent: :destroy, class_name: "GobiertoPeople::Department"
  has_many :interest_groups, dependent: :destroy, class_name: "GobiertoPeople::InterestGroup"
  has_many :gifts, through: :people, source: :received_gifts, class_name: "GobiertoPeople::Gift"
  has_many :invitations, through: :people, class_name: "GobiertoPeople::Invitation"
  has_many :trips, through: :people, class_name: "GobiertoPeople::Trip"
  has_many :historical_charges, through: :people, class_name: "GobiertoPeople::Charge"

  # GobiertoCalendars integration
  has_many :events, class_name: "GobiertoCalendars::Event", dependent: :destroy

  # Gobierto CMS integration
  has_many :pages, dependent: :destroy, class_name: "GobiertoCms::Page"
  has_many :sections, dependent: :destroy, class_name: "GobiertoCms::Section"

  # Gobierto Core integration
  has_many :site_templates, dependent: :destroy, class_name: "GobiertoCore::SiteTemplate"

  # Gobierto Plans integration
  has_many :plans, dependent: :destroy, class_name: "GobiertoPlans::Plan"
  has_many :plan_types, dependent: :destroy, class_name: "GobiertoPlans::PlanType"

  # Gobierto Indicators
  has_many :indicators, dependent: :destroy, class_name: "GobiertoIndicators::Indicator"

  # Gobierto Attachments integration
  has_many :attachments, dependent: :destroy, class_name: "GobiertoAttachments::Attachment"

  # Modules settings
  has_many :module_settings, dependent: :destroy, class_name: "GobiertoModuleSettings"

  # GobiertoCitizensCharters integration
  has_many :services, dependent: :destroy, class_name: "GobiertoCitizensCharters::Service"
  has_many :charters, through: :services, class_name: "GobiertoCitizensCharters::Charter"
  has_many :commitments, through: :charters, class_name: "GobiertoCitizensCharters::Commitment"
  has_many :editions, through: :commitments, class_name: "GobiertoCitizensCharters::Edition"

  # Gobierto Investments integration
  has_many :projects, dependent: :destroy, class_name: "GobiertoInvestments::Project"

  # GobiertoData integration
  has_many :datasets, dependent: :destroy, class_name: "GobiertoData::Dataset"
  has_many :queries, through: :datasets, class_name: "GobiertoData::Query"
  has_many :visualizations, through: :datasets, class_name: "GobiertoData::Visualization"

  # GobiertoDashboards integration
  has_many :dashboards, dependent: :destroy, class_name: "GobiertoDashboards::Dashboard"

  serialize :configuration_data

  before_save :store_configuration
  after_create :initialize_admins, :create_collections
  after_save :run_seeder

  validates :title, presence: true
  validates :domain, presence: true, uniqueness: true, domain: true
  validate :organization_required

  scope :sorted, -> { order(created_at: :desc) }

  enum visibility_level: { draft: 0, active: 1 }

  translates :name, :title

  def self.alphabetically_sorted
    all.sort_by{ |site| site.try(:name) || "" }
  end

  def self.find_by_allowed_domain(domain)
    find_by(domain: domain) unless reserved_domains.include?(domain)
  end

  def political_groups
    GobiertoPeople::Person.political_groups(self).sorted
  end

  def gobierto_people_settings
    @gobierto_people_settings ||= if configuration.available_module?("GobiertoPeople") && configuration.gobierto_people_enabled?
                                    module_settings.find_by(module_name: "GobiertoPeople")
                                  end
  end

  def gobierto_budgets_settings
    @gobierto_budgets_settings ||= if configuration.available_module?("GobiertoBudgets") && configuration.gobierto_budgets_enabled?
                                     module_settings.find_by(module_name: "GobiertoBudgets")
                                   end
  end

  def gobierto_citizens_charters_settings
    @gobierto_citizens_charters_settings ||= if configuration.available_module?("GobiertoCitizensCharters") && configuration.gobierto_citizens_charters_enabled?
                                               module_settings.find_by(module_name: "GobiertoCitizensCharters")
                                             end
  end

  def gobierto_data_settings
    @gobierto_data_settings ||= if configuration.available_module?("GobiertoData") && configuration.gobierto_data_enabled?
                                  module_settings.find_by(module_name: "GobiertoData")
                                end
  end

  def gobierto_visualizations_settings
    @gobierto_visualizations_settings ||= if configuration.available_module?("GobiertoVisualizations") && configuration.gobierto_visualizations_enabled?
                                       module_settings.find_by(module_name: "GobiertoVisualizations")
                                     end
  end

  def gobierto_observatory_settings
    @gobierto_observatory_settings ||= if configuration.available_module?("GobiertoObservatory") && configuration.gobierto_observatory_enabled?
                                       module_settings.find_by(module_name: "GobiertoObservatory")
                                     end
  end

  def settings_for_module(module_name)
    return unless respond_to?(method = "#{ module_name.underscore }_settings")

    send(method)
  end

  # If the organization_id corresponds to a municipality ID,
  # this method will return an instance of INE::Places::Place
  def place
    @place ||= if self.organization_id.present?
                 INE::Places::Place.find(self.organization_id)
               end
  end

  def configuration
    @configuration ||= SiteConfiguration.new(site_configuration_attributes)
  end

  def password_protected?
    draft?
  end

  def to_s
    name
  end

  def engines_overrides
    configuration.engine_overrides
  end

  def event_attendances
    ::GobiertoCalendars::EventAttendee.where(person_id: people.pluck(:id))
  end

  def departments_available?
    departments.any? && gobierto_people_settings.submodules_enabled.include?("departments")
  end

  def date_filter_configured?
    [
      Time.zone.parse(configuration.configuration_variables["gobierto_people_default_filter_start_date"].to_s),
      Time.zone.parse(configuration.configuration_variables["gobierto_people_default_filter_end_date"].to_s)
    ].any?
  rescue StandardError => e
    Rollbar.error(e)
    false
  end

  def root_path
    configuration.home_page.constantize.send(:root_path, self)
  end

  def multisearch(*args)
    PgSearch.multisearch(*args).where(site: self)
  end

  private

  def site_configuration_attributes
    {}.tap do |attributes|
      attributes.merge!(read_attribute(:configuration_data) || {})
      attributes.merge!('site_id' => self.id) unless new_record?
      attributes
    end
  end

  def self.reserved_domains
    @reserved_domains ||= RESERVED_SUBDOMAINS.map do |subdomain|
      "#{subdomain}." + ENV.fetch("HOST")
    end
  end
  private_class_method :reserved_domains

  def store_configuration
    self.configuration_data = self.configuration.instance_values
  end

  def initialize_admins
    preset_admin = GobiertoAdmin::Admin.preset
    if preset_admin.new_record?
      self.admins.create(preset_admin.attributes)
    else
      self.admins << preset_admin
    end
  end

  def run_seeder
    if self.saved_change_to_attribute?('configuration_data') && added_modules_after_update.any?
      added_modules_after_update.each do |module_name|
        GobiertoCommon::GobiertoSeeder::ModuleSeeder.seed(module_name, self)
      end
    end
  end

  def added_modules_after_update
    @added_modules_after_update ||= begin
      if self.configuration_data.has_key?('modules')
        configuration_data_before = self.attribute_before_last_save('configuration_data')
        if configuration_data_before && configuration_data_before.has_key?('modules')
          Array.wrap(self.configuration_data['modules']) - Array.wrap(configuration_data_before['modules'])
        else
          Array.wrap(self.configuration_data['modules'])
        end
      else
        []
      end
    end
  end

  def organization_required
    if (self.configuration.modules & %W{ GobiertoBudgetConsultations GobiertoBudgets GobiertoObservatory }).any?
      if organization_id.blank?
        errors[:base] << I18n.t('errors.messages.blank_for_modules')
      end
    end
  end

  def create_collections
    # Attachments
    collections.create! container: self, item_type: "GobiertoAttachments::Attachment", slug: "site-attachments", title: "Documentos del site"
  end
end
