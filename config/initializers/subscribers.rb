# frozen_string_literal: true

Rails.application.config.to_prepare do
  Subscribers::AdminActivity.attach_to("activities/admins")
  Subscribers::AdminGroupActivity.attach_to("activities/admins")
  Subscribers::CensusActivity.attach_to("activities/census")
  Subscribers::GobiertoPeopleActivity.attach_to("trackable")
  Subscribers::GobiertoBudgetConsultationsActivity.attach_to("trackable")
  Subscribers::GobiertoCalendarsActivity.attach_to("trackable")
  Subscribers::GobiertoCmsPageActivity.attach_to("activities/gobierto_cms_pages")
  Subscribers::GobiertoAttachmentsAttachmentActivity.attach_to("activities/gobierto_attachments_attachments")
  Subscribers::GobiertoBudgetConsultationsConsultationResponseActivity.attach_to("activities/gobierto_budget_consultations_consultation_response")
  Subscribers::GobiertoBudgetsActivity.attach_to("activities/gobierto_budgets")
  Subscribers::GobiertoCommonCollectionActivity.attach_to("activities/gobierto_common_collections")
  Subscribers::GobiertoCommonTermActivity.attach_to("activities/gobierto_common_terms")
  Subscribers::GobiertoCmsSectionActivity.attach_to("activities/gobierto_cms_sections")
  Subscribers::GobiertoCmsSectionItemActivity.attach_to("activities/gobierto_cms_section_items")
  Subscribers::GobiertoPlansPlanActivity.attach_to("activities/gobierto_plans_plans")
  Subscribers::GobiertoPlansProjectActivity.attach_to("activities/gobierto_plans_projects")
  Subscribers::GobiertoIndicatorsIndicatorActivity.attach_to("activities/gobierto_indicators_indicators")
  Subscribers::GobiertoPlansPlanTypeActivity.attach_to("activities/gobierto_plans_plan_types")
  Subscribers::UserActivity.attach_to("activities/users")
  Subscribers::SiteActivity.attach_to("activities/sites")
  Subscribers::AdminGobiertoCalendarsActivity.attach_to("activities/admin_gobierto_calendars")
  Subscribers::AdminGobiertoCitizensChartersActivity.attach_to("activities/admin_gobierto_citizens_charters")
  Subscribers::AdminGobiertoInvestmentsActivity.attach_to("activities/admin_gobierto_investments")
  Subscribers::AdminGobiertoDataActivity.attach_to("activities/admin_gobierto_data")
end

# Custom subscribers
ActiveSupport::Notifications.subscribe(/trackable/) do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.debug("Consuming event \"#{event.name}\" with payload: #{event.payload}")

  User::Subscription::NotificationBuilder.new(event).call
end
