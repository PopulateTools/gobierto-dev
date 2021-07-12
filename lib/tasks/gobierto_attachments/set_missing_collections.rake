# frozen_string_literal: true

namespace :gobierto_attachments do
  desc 'Set collection_id of attachments with collection blank from collection_item association'
  task set_missing_collections: :environment do
    GobiertoAttachments::Attachment.where(collection: nil).each do |attachment|
      associations = GobiertoCommon::CollectionItem.where(item: attachment)
      collection_item = associations.find_by(container_type: 'Site')
      if collection_item && (collections = GobiertoCommon::Collection.where(title_translations: collection_item.collection.title_translations, item_type: 'GobiertoAttachments::Attachment')).any?
        collection = collections.first
        attachment.update_attribute(:collection_id, collection.id)
        puts "== Associated to collection #{collection.title} attachment with id: #{attachment.id}"
      else
        puts "== Couldn't find a group for attachment with id: #{attachment.id}"
      end
    end
  end
end
