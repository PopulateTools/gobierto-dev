# frozen_string_literal: true

require "test_helper"

module GobiertoAttachments
  class AttachingTest < ActiveSupport::TestCase

    def site
      @site ||= sites(:madrid)
    end

    def pdf_attachment
      @pdf_attachment ||= gobierto_attachments_attachments(:pdf_attachment)
    end

    def attachable
      @attachable ||= gobierto_cms_pages(:about_site)
    end

    def test_create_attaching
      attaching = GobiertoAttachments::Attaching.create!(
        attachment: pdf_attachment,
        attachable: attachable
      )

      assert attaching.valid?

      assert_equal attaching.attachment.collection.site, attachable.site
    end

    def test_create_attaching_creating_collection
      attaching = GobiertoAttachments::Attaching.create!(
        attachment: pdf_attachment,
        attachable: attachable
      )

      assert attaching.valid?

      assert_equal attaching.attachment.collection.site, attachable.site
    end

  end
end
