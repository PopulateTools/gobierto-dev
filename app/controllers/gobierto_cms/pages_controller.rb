# frozen_string_literal: true

module GobiertoCms
  class PagesController < GobiertoCms::ApplicationController
    before_action :load_section, only: [:show]
    before_render :load_collection_pages

    def index
      @collection = find_collection

      check_collection_type
    end

    def show
      @page = find_page
      @section_item = find_section_item if @section

      check_collection_type
    end

    protected

    def find_collection
      current_site.collections.find_by!(slug: params[:id])
    end

    def load_section
      if params[:slug_section]
        @section = current_site.sections.find_by!(slug: params[:slug_section])
      end
    end

    def find_page
      page = pages_scope.find_by!(slug: params[:id])
      @collection = page.collection
      if @collection.nil? || (!page.public? && !valid_preview_token?)
        raise ActiveRecord::RecordNotFound
      end
      GobiertoCms::PageDecorator.new(page, @collection.container_type, @collection.item_type)
    end

    def find_section_item
      @section.section_items.find_by!(item: @page)
    end

    def pages_scope
      valid_preview_token? ? current_site.pages : current_site.pages.active
    end

    def load_collection_pages
      if @collection
        @pages = current_site.pages.where(id: @collection.pages_in_collection).active
      end
    end

    def check_collection_type
      render_404 and return false if @collection.item_type != "GobiertoCms::Page"
    end

    def processes_scope
      valid_preview_token? ? current_site.processes : current_site.processes.active
    end

  end
end
