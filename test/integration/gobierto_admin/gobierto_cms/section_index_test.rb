# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  module GobiertoCms
    class SectionIndexTest < ActionDispatch::IntegrationTest
      def setup
        super
        @path = admin_cms_sections_path
        # @path = admin_cms_pages_path
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

      def test_sections_index
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit @path

            table_body_rows = all('tbody tr')
            assert_equal sections.count, table_body_rows.count

            table_body_rows.each do |row|
              assert has_link?("View section")
            end

            sections.each do |section|
              assert has_content? section.title
            end
          end
        end
      end

    end
  end
end
