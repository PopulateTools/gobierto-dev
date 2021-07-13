# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  module GobiertoCms
    class SectionFormTest < ActiveSupport::TestCase

      def valid_section_form
        @valid_section_form ||= SectionForm.new(
          site_id: site.id,
          title_translations: { I18n.locale => section.title },
          slug: "section-form-slug"
        )
      end

      def invalid_section_form
        @invalid_section_form ||= SectionForm.new(
          site_id: nil,
          title_translations: nil,
          slug: nil
        )
      end

      def section
        @section ||= gobierto_cms_sections(:cms_section_madrid_1)
      end

      def site
        @site ||= sites(:madrid)
      end

      def test_save_with_valid_attributes
        assert valid_section_form.save
      end

      def test_error_messages_with_invalid_attributes
        invalid_section_form.save

        assert_equal 1, invalid_section_form.errors.messages[:site].size
      end
    end
  end
end
