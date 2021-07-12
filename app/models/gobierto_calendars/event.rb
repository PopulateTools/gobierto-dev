# frozen_string_literal: true

module GobiertoCalendars
  class Event < ApplicationRecord
    acts_as_paranoid column: :archived_at

    paginates_per 8
    ADMIN_PAGE_SIZE = 40

    attr_accessor :admin_id

    include ActsAsParanoidAliases
    include User::Subscribable
    include GobiertoCommon::UrlBuildable
    include GobiertoCommon::Searchable
    include GobiertoCommon::Sluggable
    include GobiertoCommon::Collectionable
    include GobiertoCommon::Metadatable
    include GobiertoAttachments::Attachable
    include GobiertoPeople::BelongsToPersonWithCharge

    belongs_to_person_with_historical_charge date_attribute: :starts_at

    validates :site, :collection, presence: true
    validates :slug, uniqueness: { scope: :site_id }

    translates :title, :description

    metadata_attributes :type

    multisearchable(
      against: [:title_es, :title_en, :title_ca, :searchable_description],
      additional_attributes: lambda { |item|
        {
          site_id: item.site_id,
          title_translations: item.truncated_translations(:title),
          resource_path: item.resource_path,
          searchable_updated_at: item.updated_at
        }
      },
      if: :searchable?
    )

    belongs_to :site
    belongs_to :department, class_name: "GobiertoPeople::Department", optional: true
    belongs_to :interest_group, class_name: "GobiertoPeople::InterestGroup", optional: true
    has_many :locations, class_name: "EventLocation", dependent: :destroy
    has_many :attendees, class_name: "EventAttendee", dependent: :destroy

    after_create :add_item_to_collection
    after_restore :set_slug

    scope :past,     -> { published.where("starts_at <= ?", Time.zone.now) }
    scope :upcoming, -> { published.where("starts_at > ?", Time.zone.now) }
    scope :sorted,   -> { order(starts_at: :asc) }
    scope :sorted_backwards, -> { order(starts_at: :desc) }
    scope :within_range, ->(date_range) { published.where(starts_at: date_range) }
    scope :synchronized, -> { where("external_id IS NOT NULL") }
    scope :by_date, ->(date) { where("starts_at::date = ?", date) }
    scope :sort_by_updated_at, -> { order(updated_at: :desc) }
    scope :inverse_sorted_by_id, -> { order(id: :asc) }
    scope :sorted_by_id, -> { order(id: :desc) }
    scope :with_interest_group, -> { where.not(interest_group_id: nil) }
    scope :with_department, -> { where.not(department_id: nil) }

    scope :by_collection, ->(collection) { where(collection_id: collection.id) }
    scope :by_site, ->(site) { where(site_id: site.id) }

    scope :by_person_category, ->(category) do
      category_value = if category.is_a?(String)
                         GobiertoPeople::Person.categories[category]
                       else
                         category
                       end
      raise "Invalid category #{category}" if category_value.blank?

      joins("INNER JOIN #{GobiertoPeople::Person.table_name} ON
        collection_items.container_id = #{GobiertoPeople::Person.table_name}.id AND
        #{GobiertoPeople::Person.table_name}.category = #{category_value}")
    end

    scope :by_person_party, ->(party) do
      party_value = if party.is_a?(String)
                      GobiertoPeople::Person.parties[party]
                    else
                      party
                    end
      raise "Invalid party #{party}" if party_value.blank?

      joins("INNER JOIN #{GobiertoPeople::Person.table_name} ON
        collection_items.container_id = #{GobiertoPeople::Person.table_name}.id AND
        #{GobiertoPeople::Person.table_name}.party = #{party_value}")
    end

    scope :person_events, -> do
      joins("INNER JOIN collection_items ON
          collection_items.container_type = 'GobiertoPeople::Person' AND
          collection_items.item_type = 'GobiertoCalendars::Event' AND
          collection_items.item_id = #{table_name}.id")
    end

    enum state: { pending: 0, published: 1 }

    def parameterize
      { container_slug: container.slug, slug: slug }
    end

    def past?
      starts_at <= Time.zone.now
    end

    def upcoming?
      starts_at > Time.zone.now
    end

    def active?
      published?
    end

    def synchronized?
      external_id.present?
    end

    def self.csv_columns
      [:id, :collection_title, :creator_type, :creator_id, :creator_name, :title, :description, :starts_at, :ends_at, :created_at, :updated_at]
    end

    def as_csv
      [id, collection.title, container.class.name, container.id, container.name, title, description, starts_at, ends_at, created_at, updated_at]
    end

    def attributes_for_slug
      [Time.now.strftime("%F"), title]
    end

    def add_item_to_collection
      collection.append(self)
    end

    def to_path
      return if archived?
      url_helpers.gobierto_people_person_event_path(parameterize)
    end
    alias resource_path to_path

    def to_url(options = {})
      if !public? && options[:preview] && options[:admin]
        options[:preview_token] = options[:admin].preview_token
      end
      options = options.except(:admin, :preview)
      url_helpers.gobierto_people_person_event_url(parameterize.merge(host: site_domain).merge(options))
    end

    def first_location
      locations.first
    end

    def searchable_description
      searchable_translated_attribute(description_translations)
    end

    def public?
      public_parent? && active?
    end

    private

    def site_domain
      site.domain
    end

    def public_parent?
      if person
        person.reload.public?
      else
        true
      end
    end

  end
end
