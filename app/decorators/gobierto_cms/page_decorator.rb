module GobiertoCms
  class PageDecorator < BaseDecorator
    include ActionView::Helpers::TextHelper

    def initialize(page, context = nil, item_type = nil)
      @object = page
      @context = context || page.collection.container_type
      @item_type = item_type || page.collection.item_type
    end

    attr_reader :context

    def template
      "gobierto_cms/pages/templates/#{@object.template || sub_template}"
    end

    def main_image
      object.attachments.each do |attachment|
        return attachment.url if attachment.content_type.start_with?("image/")
      end
      nil
    end

    def summary(length = 100)
      truncate(strip_tags(body), length: length)
    end

    private

    attr_reader :object, :item_type

    def sub_template
      item_type.split('::').last.downcase
    end

  end
end
