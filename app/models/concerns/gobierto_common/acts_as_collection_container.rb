module GobiertoCommon
  module ActsAsCollectionContainer
    extend ActiveSupport::Concern

    class_methods do
      def container_type_name
        to_s.underscore
      end

      def url_helpers
        Rails.application.routes.url_helpers
      end

    end

    included do

      after_destroy :clean_collection_items

      def title_as_container
        title = try(:title) || try(:name)
      end

      def container_type
        self.class.container_type_name
      end

      def news
        ids = GobiertoCommon::CollectionItem.where(collection: news_collection).pluck(:item_id)
        GobiertoCms::Page.where(id: ids, site: site).active
      end

      def events
        collection_items_table = CollectionItem.table_name
        item_type = GobiertoCalendars::Event

        site.events.joins("INNER JOIN #{collection_items_table} ON           \
          #{collection_items_table}.item_id = #{item_type.table_name}.id AND \
          #{collection_items_table}.item_type = '#{item_type}' AND           \
          container_type = '#{self.class}' AND                               \
          container_id = #{self.id}                                          \
        ")
      end

      def news_collection
        @news_collection ||= GobiertoCommon::Collection.find_by(container: self, item_type: 'GobiertoCms::News')
      end

      def events_collection
        @events_collection ||= GobiertoCommon::Collection.find_by(container: self, item_type: 'GobiertoCalendars::Event')
      end

    end

    private

    def clean_collection_items
      GobiertoCommon::CleanCollectionItemsJob.perform_later(self.class.name, self.id)
    end
  end
end
