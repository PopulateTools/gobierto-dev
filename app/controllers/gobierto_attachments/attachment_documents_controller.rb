# frozen_string_literal: true

module GobiertoAttachments
  class AttachmentDocumentsController < GobiertoAttachments::ApplicationController

    include ::PreviewTokenHelper

    before_action :load_attachment
    before_render :set_context

    def show
      @collection = @attachment.collection
      render layout: @attachment.layout if @attachment.layout
    end

    private

    def load_attachment
      @attachment = GobiertoAttachments::AttachmentDecorator.new(
        site_attachments.find_by(id: params[:id]) || site_attachments.find_by!(slug: params[:id])
      )
      raise ActiveRecord::RecordNotFound unless @attachment.public? || valid_preview_token?
    end

    def site_attachments
      current_site.attachments
    end

    def set_context
      return unless @attachment

      @current_module = @attachment.module
    end
  end
end
