# frozen_string_literal: true

module GobiertoAdmin
  module GobiertoAttachments
    class FileAttachmentsController < BaseController

      before_action :load_collection, only: [:new, :edit, :create, :update, :destroy]

      def index
        @collections = current_site.collections.by_item_type("GobiertoAttachments::Attachment")
        @file_attachments = ::GobiertoAttachments::Attachment.in_collections(current_site).sort_by_updated_at.limit(10)
        @site_file_attachments = current_site.attachments.sort_by_updated_at
      end

      def new
        @file_attachment_form = FileAttachmentForm.new(site_id: current_site.id, collection_id: collection_id)
      end

      def edit
        load_file_attachment(preview: true)
        @file_attachment_form = FileAttachmentForm.new(
          @file_attachment.attributes.except(*ignored_file_attachment_attributes).merge(site_id: current_site.id, collection_id: collection_id)
        )
      end

      def create
        @file_attachment_form = FileAttachmentForm.new(
          file_attachment_params.merge(
            site_id: current_site.id,
            collection_id: collection_id,
            admin_id: current_admin.id
          )
        )
        if @file_attachment_form.save
          track_create_activity

          redirect_to(
            edit_admin_attachments_file_attachment_path(@file_attachment_form.file_attachment.id, collection_id: collection_id),
            notice: t(".success_html", link: gobierto_attachments_document_url(id: @file_attachment_form.file_attachment.id, host: @file_attachment_form.site.domain))
          )
        else
          render :edit
        end
      end

      def update
        load_file_attachment(preview: true)

        @file_attachment_form = FileAttachmentForm.new(file_attachment_params.merge(
          id: params[:id],
          admin_id: current_admin.id,
          site_id: current_site.id,
          collection_id: collection_id
        ))

        if @file_attachment_form.save
          track_update_activity

          redirect_to(
            edit_admin_attachments_file_attachment_path(@file_attachment_form.file_attachment.id, collection_id: collection_id),
            notice: t(".success_html", link: gobierto_attachments_document_url(id: @file_attachment_form.slug, host: @file_attachment_form.site.domain))
          )
        else
          render :edit, collection_id: collection_id
        end
      end

      def destroy
        load_file_attachment
        @file_attachment.destroy
        process = find_process if params[:process_id]

        redirect_to admin_common_collection_path(@file_attachment.collection), notice: t(".success")
      end

      def recover
        @file_attachment = find_archived_file_attachment
        @file_attachment.restore

        process = find_process if params[:process_id]

        redirect_to admin_common_collection_path(@file_attachment.collection), notice: t(".success")
      end

      private

      def track_create_activity
        Publishers::GobiertoAttachmentsAttachmentActivity.broadcast_event("attachment_created", default_activity_params.merge(subject: @file_attachment_form.file_attachment))
      end

      def track_update_activity
        Publishers::GobiertoAttachmentsAttachmentActivity.broadcast_event("attachment_updated", default_activity_params.merge(subject: @file_attachment))
      end

      def load_collection
        @collection = params[:collection_id] ? current_site.collections.find(params[:collection_id]) : nil
      end

      def collection_id
        @collection ? @collection.id : nil
      end

      def default_activity_params
        { ip: remote_ip, author: current_admin, site_id: current_site.id }
      end

      def load_file_attachment(opts = {})
        @file_attachment = current_site.attachments.find(params[:id])
        @preview_item = @file_attachment if opts[:preview]
      end

      def find_archived_file_attachment
        current_site.attachments.with_archived.find(params[:file_attachment_id])
      end

      def find_process
        current_site.processes.find(params[:process_id])
      end

      def find_collection(collection_id)
        ::GobiertoCommon::Collection.find_by(id: collection_id)
      end

      def ignored_file_attachment_attributes
        %w(created_at updated_at site_id file_size current_version collection_id)
      end

      def file_attachment_params
        params.require(:file_attachment).permit(:id, :file, :name, :description, :file_name, :slug, :collection_id)
      end
    end
  end
end
