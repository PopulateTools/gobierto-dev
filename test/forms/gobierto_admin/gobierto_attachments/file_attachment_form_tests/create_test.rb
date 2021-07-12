# frozen_string_literal: true

require "test_helper"
require_relative "base_test"

module GobiertoAdmin
  module GobiertoAttachments
    module FileAttachmentFormTests
      class CreateTest < BaseTest
        def collection
          @collection ||= gobierto_common_collections(:site_attachments_cortegada)
        end

        def file_attachment_attributes
          @file_attachment_attributes ||= {
            site_id: site.id,
            admin_id: admin.id,
            collection_id: collection.id,
            name: "New attachment name",
            description: "New attachment description",
            file: uploaded_file,
            slug: "new-attachment-slug"
          }
        end

        def test_create
          form = ::GobiertoAdmin::FileAttachmentForm.new(file_attachment_attributes)

          assert form.save

          file_attachment = file_attachment_class.find(form.file_attachment.id)

          assert_equal "New attachment name", file_attachment.name
          assert_equal "New attachment description", file_attachment.description
          assert_equal "new-attachment-slug", file_attachment.slug
          assert_equal 1, file_attachment.current_version

          assert_equal "logo-madrid.png", file_attachment.file_name
          assert_equal "png", file_attachment.extension
          assert_equal file_attachment_class.file_digest(uploaded_file), file_attachment.file_digest
          assert_equal 1542, file_attachment.file_size
          assert_equal "http://www.domain.com/logo-madrid.png", file_attachment.url
        end

        def test_create_when_file_exists
          form = ::GobiertoAdmin::FileAttachmentForm.new(file_attachment_attributes)
          form.save

          new_form = ::GobiertoAdmin::FileAttachmentForm.new(file_attachment_attributes.merge(name: "Duplicated file"))
          new_form.save

          file_attachment = file_attachment_class.find(form.file_attachment.id)
          assert_equal form.file_attachment.id, new_form.file_attachment.id
          assert_equal "Duplicated file", file_attachment.name
        end

        def test_create_attachment_on_collection
          form = ::GobiertoAdmin::FileAttachmentForm.new(file_attachment_attributes.merge(
                                                           collection_id: collection.id
                                                         ))

          assert form.save

          file_attachment = file_attachment_class.find(form.file_attachment.id)

          assert_equal "New attachment name", file_attachment.name
          assert_equal collection, file_attachment.collection
        end

        def test_create_without_name
          form = ::GobiertoAdmin::FileAttachmentForm.new(
            file_attachment_attributes.except(:name)
          )

          assert form.save

          file_attachment = file_attachment_class.find(form.file_attachment.id)

          assert_equal "logo-madrid.png", file_attachment.name
        end

        def test_create_when_file_too_big
          form = ::GobiertoAdmin::FileAttachmentForm.new(file_attachment_attributes)

          Rack::Test::UploadedFile.any_instance
                                  .stubs(:size)
                                  .returns(file_attachment_class::MAX_FILE_SIZE_IN_BYTES + 1)

          refute form.save

          assert form.errors.messages.include?(:file_size)
        end

        def test_create_with_invalid_attributes
          form = ::GobiertoAdmin::FileAttachmentForm.new(site_id: nil, file: nil)

          refute form.save

          error_messages = form.errors.messages

          assert error_messages.include?(:file)
          assert error_messages.include?(:site)
        end
      end
    end
  end
end
