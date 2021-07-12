# frozen_string_literal: true

require "test_helper"

module GobiertoAttachments
  module Attachments
    class AttachmentDocumentsShowTest < ActionDispatch::IntegrationTest

      def site
        @site ||= sites(:madrid)
      end

      def pdf_attachment
        @pdf_attachment ||= gobierto_attachments_attachments(:pdf_attachment)
      end

      def pdf_collection_attachment
        @pdf_collection_attachment ||= gobierto_attachments_attachments(:pdf_collection_attachment)
      end

      def png_attachment
        @png_attachment ||= gobierto_attachments_attachments(:png_attachment_uploaded)
      end


      def test_view_attachment_document_in_participation_process_context
        with_current_site(site) do
          visit gobierto_attachments_document_url(pdf_attachment, host: site.domain)

          assert has_content? pdf_attachment.description
          assert has_content? pdf_attachment.name
        end
      end

      def test_view_attachment_without_context
        with_current_site(site) do
          visit gobierto_attachments_document_url(png_attachment, host: site.domain)

          assert has_content? png_attachment.description
          assert has_content? png_attachment.name
        end
      end

      def test_wrong_url
        with_current_site(site) do
          visit gobierto_attachments_document_url(id: "wadus", host: site.domain)
          assert_equal 404, page.status_code
        end
      end

    end
  end
end
