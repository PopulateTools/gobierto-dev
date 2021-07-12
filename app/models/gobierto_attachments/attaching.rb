# frozen_string_literal: true

module GobiertoAttachments
  class Attaching < ApplicationRecord
    belongs_to :site
    belongs_to :attachment
    belongs_to :attachable, polymorphic: true

    validates :site, :attachment, presence: true

    before_validation :set_site
    after_create :add_item_to_collection

    private

    def set_site
      self.site ||= attachment.try(:site) || attachable.try(:site)
    end

    def add_item_to_collection
      return if attachable.collection.nil?

      attachments_collection = site.collections.find_by(container_type: attachable.collection.container_type,
                                                        container_id: attachable.collection.container_id,
                                                        item_type: attachment.class.name) || create_collection

      attachment.update(collection: attachments_collection)

      attachments_collection.append(attachment)
    end

    def create_collection
      site.collections.create container_type: attachable.collection.container_type,
                              container_id: attachable.collection.container_id,
                              item_type: attachment.class.name,
                              slug: "attachment-#{attachable.collection.slug}",
                              title: "" #FIXME
    end
  end
end
