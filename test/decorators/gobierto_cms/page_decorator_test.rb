# frozen_string_literal: true

require "test_helper"

module GobiertoCms
  class PageDecoratorTest < ActiveSupport::TestCase
    def site_page_decorated
      @site_page_decorated ||= GobiertoCms::PageDecorator.new(site_page)
    end

    def themes_page_decorated
      @themes_page_decorated ||= GobiertoCms::PageDecorator.new(themes_page)
    end

    def site_page
      @site_page ||= gobierto_cms_pages(:consultation_faq)
    end

    def themes_page
      @themes_page ||= gobierto_cms_pages(:themes)
    end

    def test_main_image
      assert_equal "https://gobierto-public-resources.s3.amazonaws.com/gobierto-attachments/imagen.png", site_page_decorated.main_image
    end

    def test_template
      assert_equal "gobierto_cms/pages/templates/page", site_page_decorated.template

      site_page_decorated.template = "raw_page"
      assert_equal "gobierto_cms/pages/templates/raw_page", site_page_decorated.template
    end

    def test_summary
      assert_equal "This is the body of the page", site_page_decorated.summary
    end
  end
end
