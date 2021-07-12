# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  module GobiertoCms
    class SectionShowTest < ActionDispatch::IntegrationTest
      def setup
        super
        @path = admin_cms_pages_path
      end

      def admin
        @admin ||= gobierto_admin_admins(:nick)
      end

      def site
        @site ||= sites(:madrid)
      end

      def sections
        @sections ||= site.sections
      end

      def section_item
        @section_item ||= gobierto_cms_section_items(:cms_section_madrid_1_item_a)
      end

      def test_sections_show
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit @path

            within "#sections" do
              click_link section_item.section.title
            end

            assert has_selector?("h1", text: section_item.section.title)
            assert has_content? "Last edited pages"
          end
        end
      end
    end
  end
end
