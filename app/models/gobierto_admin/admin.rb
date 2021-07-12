# frozen_string_literal: true

module GobiertoAdmin
  class Admin < ApplicationRecord
    include Authentication::Authenticable
    include Authentication::Invitable
    include Authentication::Recoverable
    include Session::Trackable

    EMAIL_ADDRESS_REGEXP = /\A(.+)@(.+\..+)\z/

    has_many :admin_sites, dependent: :destroy
    has_many :sites, through: :admin_sites

    has_many :admin_group_memberships, class_name: "GobiertoAdmin::GroupsAdmin"
    has_and_belongs_to_many :admin_groups, ->(admin) { where(site_id: admin.sites.pluck(:id)) }, join_table: "admin_groups_admins"
    has_many :permissions, ->(admin) { joins(:admin_group).where(admin_admin_groups: { site_id: admin.sites.pluck(:id) }) }, through: :admin_groups
    has_many :global_permissions, through: :admin_groups, class_name: "Permission::Global", source: :permissions
    has_many :modules_permissions, -> { for_modules }, through: :admin_groups, class_name: "::GobiertoAdmin::GroupPermission"
    has_many :site_options_permissions, -> { for_site_options }, through: :admin_groups, class_name: "GobiertoAdmin::GroupPermission"

    has_many :gobierto_development_permissions, through: :admin_groups, class_name: "Permission::GobiertoDevelopment", source: :permissions
    has_many :gobierto_budgets_permissions, through: :admin_groups, class_name: "Permission::GobiertoBudgets", source: :permissions
    has_many :gobierto_budget_consultations_permissions, through: :admin_groups, class_name: "Permission::GobiertoBudgetConsultations", source: :permissions
    has_many :gobierto_people_permissions, through: :admin_groups, class_name: "Permission::GobiertoPeople", source: :permissions
    has_many :gobierto_plans_permissions, through: :admin_groups, class_name: "Permission::GobiertoPlans", source: :permissions
    has_many :gobierto_plans_projects, class_name: "::GobiertoPlans::Node", dependent: :nullify
    has_many :gobierto_observatory_permissions, through: :admin_groups, class_name: "Permission::GobiertoObservatory", source: :permissions
    has_many :gobierto_citizens_charters_permissions, through: :admin_groups, class_name: "Permission::GobiertoCitizensCharters", source: :permissions
    has_many :gobierto_investments_permissions, through: :admin_groups, class_name: "Permission::GobiertoInvestments", source: :permissions
    has_many :gobierto_data_permissions, through: :admin_groups, class_name: "Permission::GobiertoData", source: :permissions
    has_many :gobierto_visualizations_permissions, through: :admin_groups, class_name: "Permission::GobiertoVisualizations", source: :permissions


    has_many :api_tokens, dependent: :destroy, class_name: "GobiertoAdmin::ApiToken"

    has_many :census_imports

    before_create :set_god_flag, :generate_preview_token
    after_create :primary_api_token!

    validates :email, uniqueness: true
    validates_associated :permissions

    scope :sorted, -> { order(created_at: :desc) }
    scope :god, -> { where(god: true) }
    scope :active, -> { where.not(authorization_level: authorization_levels[:disabled]) }
    scope :regular_on_site, ->(site) { regular.joins(:sites).where(admin_admin_sites: {site_id: site.id}) }

    enum authorization_level: { regular: 0, manager: 1, disabled: 2 }

    def self.preset
      god.first || god.new(
        email: APP_CONFIG[:admins][:preset_admin_email],
        name: APP_CONFIG[:admins][:preset_admin_name],
        password: Rails.application.secrets.preset_admin_password
      )
    end

    def people_permissions
      permissions.for_people
    end

    def sites_people_permissions
      permissions.for_site_people(site_ids)
    end

    def sites
      if managing_user?
        Site.all
      elsif disabled?
        Site.none
      else
        super
      end
    end

    def destroy
      return super unless god?

      print "Do you REALLY want to destroy the God Admin ##{id}? [Yes/No]: "
      return "Skipping deletion" unless gets.chomp == "Yes"

      super
    end

    def managing_user?
      god? || manager?
    end

    def module_allowed?(module_namespace, site)
      managing_user? || send(module_namespace.underscore + "_permissions").on_site(site).any?
    end

    def module_allowed_action?(module_namespace, site, action)
      managing_user? || send(module_namespace.underscore + "_permissions").on_site(site).where(action_name: action).any?
    end

    def can_customize_site?
      managing_user? || site_options_permissions.exists?(resource_type: :customize)
    end

    def can_edit_vocabularies?
      managing_user? || site_options_permissions.exists?(resource_type: :vocabularies)
    end

    def can_edit_custom_fields?
      managing_user? || site_options_permissions.exists?(resource_type: :custom_fields)
    end

    def can_edit_templates?
      managing_user? || site_options_permissions.exists?(resource_type: :templates)
    end

    def admin_group_membership_created_at(group)
      membership = admin_group_memberships.find_by(admin_group: group)

      return unless membership

      membership.created_at
    end

    def primary_api_token
      @primary_api_token ||= api_tokens.primary.take
    end

    def primary_api_token!
      @primary_api_token = api_tokens.primary.take || api_tokens.primary.create
    end

    private

    def set_god_flag
      self.god = true unless self.class.unscoped.god.exists?

      # Always return successfully to avoid halting execution.
      true
    end

    def generate_preview_token
      self.preview_token = self.class.generate_unique_secure_token
    end
  end
end
