# frozen_string_literal: true

module GobiertoPlans
  class Plan < ApplicationRecord
    acts_as_paranoid column: :archived_at

    include ActsAsParanoidAliases
    include GobiertoCommon::Sluggable

    belongs_to :site
    belongs_to :plan_type
    belongs_to :categories_vocabulary, class_name: "GobiertoCommon::Vocabulary", foreign_key: :vocabulary_id, optional: true
    belongs_to :statuses_vocabulary, class_name: "GobiertoCommon::Vocabulary", foreign_key: :statuses_vocabulary_id, optional: true
    has_many :categories, through: :categories_vocabulary, source: :terms, class_name: "GobiertoCommon::Term"

    translates :title, :introduction, :footer

    enum visibility_level: { draft: 0, published: 1 }

    after_restore :set_slug

    validates :site, :title, :introduction, :plan_type_id, :year, presence: true
    validates :year, uniqueness: { scope: :plan_type }
    validates :slug, uniqueness: { scope: :site_id }

    scope :sort_by_updated_at, -> { order(updated_at: :desc) }
    scope :sort_by_year, -> { order(year: :desc) }

    def configuration_data
      data = read_attribute(:configuration_data)
      JSON.parse(data) unless data.blank?
    end

    def nodes
      @nodes ||= Node.joins(categories: [:vocabulary]).where(terms: { vocabulary_id: categories_vocabulary&.id }).order(position: :asc, id: :asc)
    end

    def have_indicators?
      GobiertoCommon::CustomFieldRecord.includes(:custom_field).where(custom_fields: { instance_id: id, field_type: 10 }).count > 0
    end

    def indicators
      GobiertoCommon::CustomFieldRecord.includes(:custom_field).where(custom_fields: { instance_id: id, field_type: 10 })
    end

    def levels
      categories.maximum("level") || 0
    end

    def node_size
      nodes.count
    end

    def global_progress
      nodes.average(:progress).to_f
    end

    def attributes_for_slug
      [title]
    end

    def vocabulary_shared_with_other_plans?
      return unless vocabulary_id

      self.class.with_deleted.where(vocabulary_id: vocabulary_id).where.not(id: id).exists?
    end

    def front_available_custom_fields
      available_custom_fields.where.not(uid: configuration_data&.fetch("fields_to_not_show_in_front", []))
    end

    def available_custom_fields
      instance_level_custom_fields.presence || site.custom_fields.where(class_name: "GobiertoPlans::Node").sorted
    end

    def instance_level_custom_fields
      ::GobiertoCommon::CustomField.where(instance: self).sorted
    end

  end
end
