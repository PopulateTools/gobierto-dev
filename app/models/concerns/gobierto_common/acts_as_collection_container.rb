module GobiertoCommon
  module ActsAsCollectionContainer
    extend ActiveSupport::Concern

    class_methods do

      def container_type_name
        to_s.underscore
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
        # TODO: rewrite properly as it is done for events
        news_collection ? news_collection.collection_items.map { |collection_item| collection_item.item } : []
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

      def container_path
        case self.class
        when GobiertoParticipation::Process
          gobierto_participation_process_path(self)
        end
      end

      def news_collection
        @news_collection ||= GobiertoCommon::Collection.find_by(container: self, item_type: 'GobiertoCms::Page')
      end

      def events_collection
        @events_collection ||= GobiertoCommon::Collection.find_by(container: self, item_type: 'GobiertoCalendars::Event')
      end

    end

    def self.container_klass_for
      {
        GobiertoParticipation::Process.container_type_name => GobiertoParticipation::Process
      }
    end

    private

    def clean_collection_items
      GobiertoCommon::CleanCollectionItemsJob.perform_later(self.site_id, self.class.name, self.id)
    end

  end
end
