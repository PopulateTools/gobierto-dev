# frozen_string_literal: true

class User::SubscriptionPreferencesForm < BaseForm

  attr_accessor(
    :user,
    :site,
    :notification_frequency,
    :modules,
    :gobierto_people_people,
    :gobierto_budget_consultations_consultations,
    :site_to_subscribe
  )

  validates :user, :site, :notification_frequency, presence: true

  def save
    save_subscriptions if valid?
  end

  def specific_subscriptions
    @specific_subscriptions ||= filter_subscriptions_by_available_modules(user.subscriptions.specific.where(site: site)).map(&:subscribable)
  end

  def module_level_subscriptions
    @module_level_subscriptions ||= filter_subscriptions_by_available_modules(user.subscriptions.generic.where(site: site)).map { |m| m.subscribable_type.underscore }
  end

  private

  def modules_classes
    @modules_classes ||= modules.reject(&:blank?).map do |mod|
      mod.camelize.constantize
    end
  end

  def save_subscriptions
    @user = user.tap do |user_attributes|
      user_attributes.notification_frequency = notification_frequency
    end

    if @user.valid?
      @user.save

      update_subscription_to_site(site_to_subscribe) || begin
        update_subscriptions_to_modules
        update_subscriptions_to_people(gobierto_people_people)
        update_subscriptions_to_consultations(gobierto_budget_consultations_consultations)
      end

      @user
    else
      promote_errors(@user.errors)

      false
    end
  end

  def update_subscriptions_to_modules
    site.configuration.modules.reject(&:blank?).map(&:constantize).each do |mod|
      next if broader_level_subscription_to?(mod)
      modules_classes.include?(mod) ? @user.subscribe_to!(mod, site) : @user.unsubscribe_from!(mod, site)
    end
  end

  def update_subscriptions_to_people(people)
    people = Array(people)
    return if broader_level_subscription_to?(GobiertoPeople::Person.new)

    people.each do |person_id|
      next if person_id.blank?

      person = GobiertoPeople::Person.find(person_id)
      @user.subscribe_to!(person, site)
    end

    (site.people.active.pluck(:id).map(&:to_s) - people).each do |person_id|
      next if person_id.blank?

      person = site.people.find(person_id)
      @user.unsubscribe_from!(person, site)
    end
  end

  def update_subscription_to_site(site_to_subscribe_id)
    site_subscription = site_to_subscribe_id != "0"
    if site_subscription
      @user.subscribe_to!(site, site)
    else
      @user.unsubscribe_from!(site, site)
    end
    site_subscription
  end

  def update_subscriptions_to_consultations(budget_consultations)
    budget_consultations = Array(budget_consultations)
    return if broader_level_subscription_to?(GobiertoBudgetConsultations::Consultation.new)

    budget_consultations.each do |consultation_id|
      next if consultation_id.blank?

      consultation = GobiertoBudgetConsultations::Consultation.find(consultation_id)
      @user.subscribe_to!(consultation, site)
    end

    (site.budget_consultations.active.pluck(:id).map(&:to_s) - budget_consultations).each do |consultation_id|
      next if consultation_id.blank?

      consultation = site.budget_consultations.find(consultation_id)
      @user.unsubscribe_from!(consultation, site)
    end
  end

  def broader_level_subscription_to?(subscribable)
    user.subscribed_to?(subscribable, site, :user_subscribed_by_broader_subscription_to?)
  end

  def filter_subscriptions_by_available_modules(subscriptions)
    available_modules_regexp = Regexp.new("^[#{site.configuration.modules_with_notifications.join("|")}]")
    subscriptions.select do |sub|
      available_modules_regexp.match?(sub.subscribable_type)
    end
  end
end
