# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  module GobiertoCms
    class ArchivePageTest < ActionDispatch::IntegrationTest
      def setup
        super
        # @path = admin_participation_process_pages_path(process_id: process.id)
        @path = admin_cms_pages_path
      end

      def admin
        @admin ||= gobierto_admin_admins(:nick)
      end

      def site
        @site ||= sites(:madrid)
      end

      def collection
        @collection ||= gobierto_common_collections(:site_news)
      end

      def site_news_page
        @site_news_page ||= gobierto_cms_pages(:site_news_1)
      end

      def consultation_faq_page
        @consultation_faq_page ||= gobierto_cms_pages(:consultation_faq)
      end

      def site_pages_collection
        ::GobiertoCommon::Collection.find_by(container: site, item_type: "GobiertoCms::Page")
      end

      def test_archive_page_success_and_restore_page_success
        with_javascript do
          with_signed_in_admin(admin) do
            with_current_site(site) do
              visit @path

              within "tr#collection-item-#{collection.id}" do
                click_link "Site news"
              end

              within "#page-item-#{site_news_page.id}" do
                find("a[data-method='delete']").click
              end

              page.driver.browser.switch_to.alert.accept
              assert has_message?("Page archived successfully")

              click_on "Archived elements"

              within "tr#page-item-#{site_news_page.id}" do
                click_on "Recover element"
              end

              page.driver.browser.switch_to.alert.accept

              assert has_message?("The page has been successfully recovered")
            end
          end
        end
      end

    end
  end
end
