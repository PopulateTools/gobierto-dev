# frozen_string_literal: true

require "test_helper"
require_relative "base_test"

module GobiertoAdmin
  module GobiertoAttachments
    module FileAttachmentFormTests
      class UpdateTest < BaseTest
        def collection
          @collection ||= gobierto_common_collections(:site_news)
        end

        def existing_attachment
          @existing_attachment ||= gobierto_attachments_attachments(:pdf_attachment)
        end

        def file_attachment_attributes
          @file_attachment_attributes ||= {
            id: existing_attachment.id,
            site_id: site.id,
            admin_id: admin.id,
            collection_id: collection.id,
            name: "Edited name",
            description: "Edited description",
            slug: "edited-slug"
          }
        end

        def test_update_basic_attributes
          form = ::GobiertoAdmin::FileAttachmentForm.new(file_attachment_attributes)

          assert form.save

          file_attachment = file_attachment_class.find(existing_attachment.id)

          assert_equal "Edited name", file_attachment.name
          assert_equal "Edited description", file_attachment.description
          assert_equal "edited-slug", file_attachment.slug
          assert_equal existing_attachment.current_version, file_attachment.current_version # version shouldn't be increased
        end

        def test_update_file
          form = ::GobiertoAdmin::FileAttachmentForm.new(file_attachment_attributes.merge(
            file: uploaded_file
          ))

          assert form.save

          file_attachment = file_attachment_class.find(existing_attachment.id)

          assert_equal existing_attachment.current_version + 1, file_attachment.current_version # version should be increased

          assert_equal "logo-madrid.png", file_attachment.file_name
          assert_equal "png", file_attachment.extension
          assert_equal file_attachment_class.file_digest(uploaded_file), file_attachment.file_digest
          assert_equal 1542, file_attachment.file_size
          assert_equal "http://www.domain.com/logo-madrid.png", file_attachment.url
        end

        def test_update_with_invalid_attributes
          form = ::GobiertoAdmin::FileAttachmentForm.new(id: existing_attachment.id)

          refute form.save

          error_messages = form.errors.messages

          refute error_messages.include?(:file)
          assert error_messages.include?(:site)
        end
      end
    end
  end
end
