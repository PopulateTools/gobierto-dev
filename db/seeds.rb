# frozen_string_literal: true

fixtures_to_load = [
  "sites",
  "users",
  "census_items",
  "gobierto_module_settings",
  "gobierto_admin/admins",
  "gobierto_admin/admin_sites",
  "user/verification/census_verifications",
  "user/subscriptions",
  "user/notifications",
  "gobierto_budgets/categories",
  "gobierto_budget_consultations/consultations",
  "gobierto_budget_consultations/consultation_items",
  "gobierto_budget_consultations/consultation_responses",
  "gobierto_people/departments",
  "gobierto_people/gifts",
  "gobierto_people/interest_groups",
  "gobierto_people/invitations",
  "gobierto_people/people",
  "gobierto_people/person_statements",
  "gobierto_people/person_posts",
  "gobierto_people/trips",
  "gobierto_common/collections",
  "gobierto_common/collection_items",
  "gobierto_common/terms",
  "gobierto_common/vocabularies",
  "gobierto_common/custom_fields",
  "gobierto_common/custom_field_records",
  "gobierto_calendars/events",
  "gobierto_calendars/event_locations",
  "gobierto_calendars/event_attendees",
  "gobierto_calendars/calendar_configurations",
  "gobierto_cms/pages",
  "gobierto_cms/sections",
  "gobierto_cms/section_items",
  "gobierto_attachments/attachments",
  "gobierto_attachments/attachings",
  "versions",
  "gobierto_admin/group_permissions",
  "gobierto_plans/plan_types",
  "gobierto_plans/plans",
  "gobierto_plans/nodes",
  "gobierto_indicators/indicators",
  "gobierto_core/templates",
  "gobierto_citizens_charters/services",
  "gobierto_citizens_charters/charters",
  "gobierto_citizens_charters/commitments",
  "gobierto_citizens_charters/editions",
  "gobierto_dashboards/dashboards"
]

ENV["FIXTURES"] = fixtures_to_load.join(",")
Rake::Task["db:fixtures:load"].invoke
::GobiertoCommon::ContentBlock.reset_column_information
Rake::Task["gobierto_people:counter_cache:reset"].invoke

GobiertoCommon::Term.reset_position!

::GobiertoCommon::ContentBlock.reset_column_information

Site.all.each do |site|
  if site.configuration.gobierto_people_enabled?
    GobiertoCommon::GobiertoSeeder::ModuleSeeder.seed("GobiertoPeople", site)
  end
end

::GobiertoCore::Template.create template_path: "gobierto_participation/welcome/index"
::GobiertoCore::Template.create template_path: "gobierto_participation/layouts/navigation_process"
::GobiertoCore::Template.create template_path: "layouts/application"

::BudgetsSeeder.seed!
