# frozen_string_literal: true

require "test_helper"
require "base64"

module GobiertoAdmin
  module GobiertoAttachments
    class AttachmentTest < ActionDispatch::IntegrationTest
      def site
        @site ||= sites(:madrid)
      end

      def collection
        @collection ||= gobierto_common_collections(:site_attachments)
      end

      def admin
        @admin ||= gobierto_admin_admins(:nick)
      end

      def attachment_attributes
        @attachment_attributes ||= %w(id site_id name description file_name file_digest url human_readable_url file_size current_version created_at)
      end

      def pdf_file
        @pdf_file ||= file_fixture("gobierto_attachments/attachment/pdf-attachment.pdf")
      end

      def new_pdf_file
        @new_pdf_file ||= file_fixture("gobierto_attachments/attachment/new-pdf-attachment.pdf")
      end

      def xlsx_file
        @xlsx_file ||= file_fixture("gobierto_attachments/attachment/xlsx-attachment.xlsx")
      end

      def pdf_attachment
        gobierto_attachments_attachments(:pdf_attachment)
      end

      def attachable
        @attachable ||= gobierto_cms_pages(:consultation_faq)
      end

      def test_requests_need_authentication
        get admin_attachments_api_attachments_path(site_id: site.id)

        assert_response :unauthorized
      end

      def test_attachments_index
        login_admin_for_api(admin)

        get admin_attachments_api_attachments_path

        json_response = JSON.parse(response.body)
        attachments = json_response["attachments"]
        attachment = attachments.first

        assert_response :success

        assert_equal 8, attachments.size
        assert array_match(attachment_attributes, attachment.keys)

        assert_equal "Attachment Name", attachment["name"]
        assert_equal 49, attachment["file_size"]
        assert_equal "attachment", attachment["file_name"]
        assert_equal "b6db2818dffd2fb2fc20836bebd59b87", attachment["file_digest"]
        assert_equal "http://host.com/attachments/super-long-and-ugly-aws-id/attachment", attachment["url"]
        assert_equal "Description of attachment without extension", attachment["description"]
        assert_equal 3, attachment["current_version"]
        assert_equal site.id, attachment["site_id"]
      end

      def test_attachments_index_for_attachable
        login_admin_for_api(admin)

        payload = {
          attachable_id: attachable.id,
          attachable_type: attachable.class.to_s
        }

        get admin_attachments_api_attachments_path(payload)

        json_response = JSON.parse(response.body)
        attachments = json_response["attachments"]
        attachment = attachments.first

        assert_response :success

        assert_equal 1, json_response.size
        assert_equal "XLSX Attachment Name", attachment["name"]
      end

      def test_attachment_index_search
        login_admin_for_api(admin)

        payload = {
          search_string: "PDF"
        }

        ::GobiertoAttachments::Attachment.stubs(:search).returns([pdf_attachment])

        get admin_attachments_api_attachments_path(payload)

        json_response = JSON.parse(response.body)
        attachments = json_response["attachments"]

        assert_response :success

        assert_equal 1, attachments.size
        assert_equal "PDF Attachment Name", attachments.first["name"]
      end

      def test_attachments_show_success
        login_admin_for_api(admin)

        get admin_attachments_api_attachment_path(pdf_attachment.id)

        json_response = JSON.parse(response.body)
        attachment = json_response["attachment"]

        assert_response :success

        assert array_match(attachment_attributes, attachment.keys)
        assert_equal "PDF Attachment Name", attachment["name"]
        assert_equal "http://host.com/attachments/super-long-and-ugly-aws-id/pdf-attachment.pdf", attachment["url"]
      end

      def test_attachments_show_error
        login_admin_for_api(admin)

        unexistent_id = 666

        get admin_attachments_api_attachment_path(unexistent_id)

        assert_response :not_found
      end

      def test_attachments_create_success
        login_admin_for_api(admin)

        payload = {
          attachment: {
            collection_id: collection.id,
            name: "New attachment name",
            description: "New attachment description",
            file_name: "new-pdf-attachment.pdf",
            file: ::Base64.strict_encode64(new_pdf_file.read)
          }
        }

        ::GobiertoAdmin::FileUploadService.any_instance.stubs(:upload!).returns("http://host.com/attachments/super-long-and-ugly-aws-id/new-pdf-attachment.pdf")

        post admin_attachments_api_attachments_path(payload)

        response_body = JSON.parse(response.body)
        attachment = response_body["attachment"]

        assert_response :success

        assert array_match(attachment_attributes, attachment.keys)

        assert_equal "New attachment name", attachment["name"]
        assert_equal "new-pdf-attachment.pdf", attachment["file_name"]
        assert_equal "http://host.com/attachments/super-long-and-ugly-aws-id/new-pdf-attachment.pdf", attachment["url"]
        assert_equal 1, attachment["current_version"]
      end

      def test_attachments_create_twice_success
        login_admin_for_api(admin)

        payload = {
          attachment: {
            collection_id: collection.id,
            name: "New attachment name",
            description: "New attachment description",
            file_name: "new-pdf-attachment.pdf",
            file: ::Base64.strict_encode64(new_pdf_file.read)
          }
        }

        ::GobiertoAdmin::FileUploadService.any_instance.stubs(:upload!).returns("http://host.com/attachments/super-long-and-ugly-aws-id/new-pdf-attachment.pdf")
        assert_difference "::GobiertoAttachments::Attachment.count", 1 do
          post admin_attachments_api_attachments_path(payload)
          assert_response :success
        end

        assert_no_difference "::GobiertoAttachments::Attachment.count" do
          post admin_attachments_api_attachments_path(payload)
          assert_response :success
        end
      end

      def test_attachments_create_error
        login_admin_for_api(admin)

        payload = {
          attachment: { name: "Incomplete attachment info" }
        }

        post admin_attachments_api_attachments_path, params: payload

        response_body = JSON.parse(response.body)

        assert_response :bad_request
        assert_equal "Invalid payload", response_body["error"]
      end

      def test_attachments_update_success
        login_admin_for_api(admin)

        payload = {
          attachment: {
            id: pdf_attachment.id,
            collection_id: collection.id,
            name: "Replace with new PDF file",
            description: nil,
            file_name: "new-pdf-attachment.pdf",
            file: ::Base64.strict_encode64(new_pdf_file.read)
          }
        }

        ::GobiertoAdmin::FileUploadService.any_instance.stubs(:upload!).returns("http://host.com/attachments/super-long-and-ugly-aws-id/new-pdf-attachment.pdf")

        patch admin_attachments_api_attachment_path(pdf_attachment.id), params: payload

        # Check DB record was updated

        db_pdf_attachment = ::GobiertoAttachments::Attachment.find(pdf_attachment.id)

        assert_equal "Replace with new PDF file", db_pdf_attachment.name
        assert_nil db_pdf_attachment.description
        assert_equal "http://host.com/attachments/super-long-and-ugly-aws-id/new-pdf-attachment.pdf", db_pdf_attachment.url
        assert_equal "new-pdf-attachment.pdf", db_pdf_attachment.file_name
        assert_equal 2, db_pdf_attachment.current_version

        # Check HTTP response returns updated info

        response_body = JSON.parse(response.body)
        attachment = response_body["attachment"]

        assert_response :success

        assert array_match(attachment_attributes, attachment.keys)

        assert_equal pdf_attachment.id, attachment["id"]
        assert_equal "Replace with new PDF file", attachment["name"]
        assert_nil attachment["description"]
        assert_equal "new-pdf-attachment.pdf", attachment["file_name"]
        assert_equal 2, attachment["current_version"]
      end

      def test_attachments_destroy_success
        login_admin_for_api(admin)

        payload = {
          attachment: { id: pdf_attachment.id }
        }

        delete admin_attachments_api_attachment_path(pdf_attachment.id), params: payload

        assert_response :success

        assert_raises ActiveRecord::RecordNotFound do
          ::GobiertoAttachments::Attachment.find(pdf_attachment.id)
        end
      end

      def test_attachments_destroy_error
        login_admin_for_api(admin)

        unexistent_id = 666

        payload = {
          attachment: { id: unexistent_id }
        }

        delete admin_attachments_api_attachment_path(unexistent_id), params: payload

        assert_response :not_found
      end
    end
  end
end
