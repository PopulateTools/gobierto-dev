# frozen_string_literal: true

module GobiertoAdmin
  module GobiertoCommon
    class CollectionForm < BaseForm

      attr_accessor(
        :id,
        :site_id,
        :title_translations,
        :slug,
        :container_global_id,
        :item_type
      )

      delegate :persisted?, to: :collection

      validates :site, presence: true

      def save
        save_collection if valid?
      end

      def container
        @container ||= GlobalID::Locator.locate(container_global_id)
      end

      def collection
        @collection ||= collection_class.find_by(id: id).presence || build_collection
      end

      def site_id
        @site_id ||= collection.try(:site_id)
      end

      def site
        @site ||= Site.find_by(id: site_id)
      end

      private

      def build_collection
        collection_class.new
      end

      def collection_class
        ::GobiertoCommon::Collection
      end

      def save_collection
        @collection = collection.tap do |collection_attributes|
          collection_attributes.site_id = site_id
          collection_attributes.title_translations = title_translations
          collection_attributes.slug = slug
          collection_attributes.container = container
          collection_attributes.item_type = item_type
        end

        if @collection.valid?
          @collection.save

          @collection
        else
          promote_errors(@collection.errors)

          false
        end
      end

    end
  end
end
