# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  module GobiertoAttachments
    class CreateFileAttachmentTest < ActionDispatch::IntegrationTest
      def setup
        super
        @path = admin_attachments_file_attachments_path
      end

      def collection
        # @collection ||= gobierto_common_collections(:files)
        @collection ||= gobierto_common_collections(:site_attachments)
      end

      def admin
        @admin ||= gobierto_admin_admins(:nick)
      end

      def site
        @site ||= sites(:madrid)
      end

      def test_create_file_attachments_errors
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit @path

            # click_link "Files"
            click_link "Site attachments"
            assert has_selector?("h1", text: "Site attachments")

            click_link "New"
            assert has_selector?("h1", text: "New document")
            click_button "Create"
            assert has_alert?("File can't be blank")
          end
        end
      end

      def test_create_file_attachments_with_name
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit @path

            click_link "Site attachments"
            assert has_selector?("h1", text: "Site attachment")

            click_link "New"
            assert has_selector?("h1", text: "New document")

            fill_in "file_attachment_name", with: "My file_attachment"
            fill_in "file_attachment_description", with: "My file_attachment description"
            attach_file "file_attachment_file", Rails.root.join("test/fixtures/files/gobierto_attachments/attachment/pdf-collection-update-attachment.pdf")

            with_stubbed_s3_file_upload do
              click_button "Create"
            end

            assert has_message?("Attachment created successfully.")
            file_attachment = ::GobiertoAttachments::Attachment.find_by(name: "My file_attachment",
                                                                        description: "My file_attachment description")
            activity = Activity.last
            assert_equal file_attachment, activity.subject
            assert_equal admin, activity.author
            assert_equal site.id, activity.site_id
            assert_equal "gobierto_attachments.attachment_created", activity.action

            click_link "View the document"

            assert has_content?("My file_attachment")
          end
        end
      end

      def test_create_file_attachments_without_name
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit @path

            # click_link "Files"
            click_link "Site attachments"
            assert has_selector?("h1", text: "Site attachments")

            click_link "New"
            assert has_selector?("h1", text: "New document")

            fill_in "file_attachment_description", with: "My file_attachment description"
            attach_file "file_attachment_file", Rails.root.join("test/fixtures/files/gobierto_attachments/attachment/pdf-collection-update-attachment.pdf")

            with_stubbed_s3_file_upload do
              click_button "Create"
            end

            assert has_message?("Attachment created successfully.")
          end
        end
      end
    end
  end
end
