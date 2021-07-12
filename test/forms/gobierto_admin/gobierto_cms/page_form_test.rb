# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  module GobiertoCms
    class PageFormTest < ActiveSupport::TestCase

      def valid_page_form_attributes
        @valid_page_form_attributes ||= {
          site_id: site.id,
          title_translations: { I18n.locale => page.title },
          body_translations: { I18n.locale => page.body },
          slug: "page-form-slug",
          collection_id: collection.id,
          published_on: Time.zone.parse('30-12-1994 2:00'),
          visibility_level: page.visibility_level,
          template: nil
        }
      end

      def valid_page_form
        @valid_page_form ||= PageForm.new(valid_page_form_attributes)
      end

      def invalid_page_form
        @invalid_page_form ||= PageForm.new(
          site_id: nil,
          title_translations: nil,
          body_translations: nil,
          slug: nil,
          visibility_level: nil,
          published_on: nil,
          template: nil
        )
      end

      def page
        @page ||= gobierto_cms_pages(:consultation_faq)
      end

      def site
        @site ||= sites(:santander)
      end

      def collection
        @collection ||= gobierto_common_collections(:site_news)
      end

      def test_save_with_valid_attributes
        assert valid_page_form.save

        page = valid_page_form.page.reload

        assert_equal Time.zone.parse('30-12-1994 2:00'), page.published_on
      end

      def test_assigns_default_published_date
        page_form = PageForm.new(valid_page_form_attributes.except(:published_on))

        assert page_form.save
        assert page_form.page.published_on.present?
      end

      def test_error_messages_with_invalid_attributes
        invalid_page_form.save

        assert_equal 1, invalid_page_form.errors.messages[:site].size
      end
    end
  end
end
