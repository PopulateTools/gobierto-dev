# frozen_string_literal: true

require "test_helper"

module GobiertoAttachments
  class AttachmentTest < ActiveSupport::TestCase

    def setup
      super
      Pathname.any_instance.stubs(:close).returns(nil)
    end

    def site
      @site ||= sites(:madrid)
    end

    def pdf_attachment
      @pdf_attachment ||= gobierto_attachments_attachments(:pdf_attachment)
    end

    def xlsx_attachment
      @xlsx_attachment ||= gobierto_attachments_attachments(:xlsx_attachment)
    end

    def attachment
      @attachment ||= gobierto_attachments_attachments(:attachment)
    end

    def txt_pdf_attachment
      @txt_pdf_attachment ||= gobierto_attachments_attachments(:txt_pdf_attachment)
    end

    def uploaded_pdf_file
      @uploaded_pdf_file ||= ActionDispatch::Http::UploadedFile.new(
        filename: "pdf-attachment.pdf",
        tempfile: file_fixture("gobierto_attachments/attachment/pdf-attachment.pdf").open
      )
    end

    def uploaded_new_pdf_file
      @uploaded_new_pdf_file ||= ActionDispatch::Http::UploadedFile.new(
        filename: "new-pdf-attachment.pdf",
        tempfile: file_fixture("gobierto_attachments/attachment/new-pdf-attachment.pdf").open
      )
    end

    def uploaded_xlsx_file
      @uploaded_xlsx_file ||= ActionDispatch::Http::UploadedFile.new(
        filename: "xlsx-attachment.xlsx",
        tempfile: file_fixture("gobierto_attachments/attachment/xlsx-attachment.xlsx").open
      )
    end

    def uploaded_txt_pdf_file
      @uploaded_txt_pdf_file ||= ActionDispatch::Http::UploadedFile.new(
        filename: "txt-pdf-attachment.txt.pdf",
        tempfile: file_fixture("gobierto_attachments/attachment/txt-pdf-attachment.txt.pdf").open
      )
    end

    def file_digest(file)
      Attachment.file_digest(file)
    end

    def test_valid
      assert attachment.valid?
    end

    def test_create_attachment
      new_attachment = Attachment.create!(
        site: site,
        name: "New attachment name",
        description: "New attachment description",
        file: uploaded_new_pdf_file,
        file_name: "new-pdf-attachment.pdf",
        file_digest: file_digest(uploaded_new_pdf_file),
        file_size: uploaded_new_pdf_file.size,
        url: "http://host.com/attachments/super-long-and-ugly-aws-id/new-pdf-attachment.pdf",
        current_version: 1
      )

      assert new_attachment.valid?

      assert_equal "New attachment name", new_attachment.name
      assert_equal "New attachment description", new_attachment.description
      assert_equal "new-pdf-attachment.pdf", new_attachment.file_name
      assert_equal file_digest(uploaded_new_pdf_file), new_attachment.file_digest
      assert_equal uploaded_new_pdf_file.size, new_attachment.file_size

      assert_equal 1, new_attachment.current_version
      assert_equal 1, new_attachment.versions.size
    end

    def test_create_attachment_with_duplicated_file
      assert_raises ActiveRecord::RecordInvalid do
        Attachment.create!(site: site, name: "pdf-attachment.pdf", file: uploaded_pdf_file)
      end
    end

    def test_abort_create_attachment_if_too_big
      uploaded_new_pdf_file.stubs(:size).returns(Attachment::MAX_FILE_SIZE_IN_BYTES + 1)

      new_attachment = Attachment.create(
        site: site,
        name: "Attachment too big",
        file: uploaded_new_pdf_file
      )

      refute new_attachment.valid?
    end

    def test_update_attachment_metadata
      pdf_attachment.update!(name: "(SECOND EDIT) PDF Attachment Name")

      assert_equal 1, pdf_attachment.current_version
      assert_equal 1, pdf_attachment.versions.size

      assert_equal "(SECOND EDIT) PDF Attachment Name", pdf_attachment.name
    end

    def test_destroy_attachment
      pdf_attachment.destroy

      assert_raises ActiveRecord::RecordNotFound do
        GobiertoAttachments::Attachment.find(pdf_attachment.id)
      end

      last_version = PaperTrail::Version.where(item_id: pdf_attachment.id).last

      assert "destroy", last_version.event
    end

    def test_attachment_extension
      assert_equal "pdf", pdf_attachment.extension
      assert_equal "xlsx", xlsx_attachment.extension
      assert_equal "", attachment.extension
      assert_equal "pdf", txt_pdf_attachment.extension
    end

    def test_destroy
      attachment.destroy

      assert attachment.slug.include?("archived-")
    end

    def test_human_readable_path
      attachment.id = 1

      assert_equal "/docs/1", attachment.human_readable_path
    end

    def test_human_readable_url
      expected_url = "http://madrid.gobierto.test/docs/#{attachment.id}"
      assert_equal expected_url, attachment.human_readable_url
    end

    def test_to_url
      expected_url = "http://madrid.gobierto.test/documento/#{attachment.id}"
      assert_equal expected_url, attachment.to_url
    end

  end
end
