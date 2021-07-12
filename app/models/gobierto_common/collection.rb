# frozen_string_literal: true

module GobiertoCommon
  class Collection < ApplicationRecord
    include User::Subscribable
    include GobiertoCommon::UrlBuildable
    include GobiertoCommon::Sluggable

    belongs_to :site
    belongs_to :container, polymorphic: true, optional: true
    has_many :collection_items, dependent: :destroy
    has_one :calendar_configuration, class_name: "GobiertoCalendars::CalendarConfiguration"

    translates :title

    validates :site, :title, :item_type, presence: true
    validates :slug, uniqueness: { scope: :site_id }
    validate :container_id_with_container_type_and_item_type

    attr_reader :container

    scope :by_item_type, ->(item_type) { where(item_type: item_type) }

    after_update :update_collection_items

    def container_id_with_container_type_and_item_type
      unless item_type == "GobiertoCms::Page"
        if new_record? && site.collections.where(container_id: container_id,
                                                 container_type: container_type,
                                                 item_type: item_type).any?
          errors.add(:container_id, I18n.t("errors.messages.collection_taken"))
        end
      end
    end

    def news_in_collection
      collection_items.news.pluck(:item_id)
    end

    def pages_in_collection
      collection_items.pages.pluck(:item_id)
    end

    def pages_or_news_in_collection
      collection_items.pages_and_news.pluck(:item_id)
    end

    def file_attachments_in_collection
      collection_items.attachments.pluck(:item_id)
    end

    def events_in_collection
      collection_items.events.pluck(:item_id)
    end

    def container
      if container_id.present?
        super
      else
        container_type.constantize
      end
    end

    def self.collector_classes
      [Site, GobiertoCommon::Term]
    end

    def self.type_classes(item_type)
      if item_type == "Page"
        [[::GobiertoCms::Page.model_name.human, ::GobiertoCms::Page.name],
         [I18n.t("activerecord.models.gobierto_cms/news"), "GobiertoCms::News"]]
      elsif item_type == "Attachment"
        [[::GobiertoAttachments::Attachment.model_name.human, ::GobiertoAttachments::Attachment.name]]
      elsif item_type == "Event"
        [[::GobiertoCalendars::Event.model_name.human, ::GobiertoCalendars::Event.name]]
      else
        [[::GobiertoCms::Page.model_name.human, ::GobiertoCms::Page.name],
         [I18n.t("activerecord.models.gobierto_cms/news"), "GobiertoCms::News"],
         [::GobiertoAttachments::Attachment.model_name.human, ::GobiertoAttachments::Attachment.name],
         [::GobiertoCalendars::Event.model_name.human, ::GobiertoCalendars::Event.name]]
      end
    end

    def append(item)
      create_collection_items(item)
    end

    def calendar_integration
      if calendar_configuration
        case calendar_configuration.integration_name
        when "ibm_notes"
          GobiertoPeople::IbmNotes::CalendarIntegration
        when "google_calendar"
          GobiertoPeople::GoogleCalendar::CalendarIntegration
        when "microsoft_exchange"
          GobiertoPeople::MicrosoftExchange::CalendarIntegration
        end
      end
    end

    def container_printable_name
      container.try(:name) || container.try(:title)
    end

    def public?
      container.try(:reload).try(:public?) != false
    end

    private

    def containers_hierarchy(container)
      [
        site_for_container(container),
        gobierto_module_for_container(container),
        term_for_container(container),
        gobierto_module_instance_for_container(container)
      ].compact.uniq
    end

    def site_for_container(container)
      if container.is_a?(Site)
        [container.class.name, container.id]
      else
        [site.class.name, site.id]
      end
    end

    def gobierto_module_for_container(container)
      if container.is_a?(Module)
        [container.name, nil]
      elsif !container_is_a_collector?(container)
        [container.class.module_parent.name, nil]
      end
    end

    def gobierto_module_instance_for_container(container)
      if !container.is_a?(Module) && !container_is_a_collector?(container)
        [container.class.name, container.id]
      end
    end

    def term_for_container(container)
      if container.is_a?(GobiertoCommon::Term)
        [container.class.name, container.id]
      end
    end

    def container_is_a_collector?(container)
      self.class.collector_classes.include?(container.class)
    end

    def parameterize
      if container.is_a? ::GobiertoPeople::Person
        { container_slug: container.slug }
      else
        { id: slug }
      end
    end

    def attributes_for_slug
      [title]
    end

    def update_collection_items
      if (saved_changes.keys & %W(container_id container_type)).any?
        items = collection_items.pluck(:item_type, :item_id)
        collection_items.clear
        items.each do |item_type, item_id|
          item_type = "GobiertoCms::Page" if item_type == "GobiertoCms::News"
          create_collection_items(item_type.constantize.find(item_id))
        end
      end
      if saved_changes.keys.include?("item_type")
        collection_items.update_all(item_type: self.item_type)
      end
    end

    def create_collection_items(item)
      containers_hierarchy(container).each do |container_type, container_id|
        CollectionItem.find_or_create_by! collection_id: id,
                                          container_type: container_type,
                                          container_id: container_id,
                                          item_id: item.id,
                                          item_type: item_type
      end
    end

    def singular_route_key
      if container.is_a?(::GobiertoPeople::Person) && item_type == "GobiertoCalendars::Event"
        :gobierto_people_person_events
      elsif container.is_a? Site
        if item_type == "GobiertoCms::News"
          :gobierto_cms_news_index
        elsif item_type == "GobiertoCms::Page"
          :gobierto_cms_pages
        end
      end
    end

  end
end
