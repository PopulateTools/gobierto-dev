# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  module GobiertoCms
    class UpdatePageTest < ActionDispatch::IntegrationTest

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

      def cms_page
        @cms_page ||= gobierto_cms_pages(:privacy)
      end

      def collection
        @collection ||= gobierto_common_collections(:site_news)
      end

      def current_uri_query_params
        URI.parse(current_url).query
      end

      def chosen_publication_date
        Time.zone.parse("2017-01-01 00:00")
      end

      def test_update_page
        with_javascript do
          with_signed_in_admin(admin) do
            with_current_site(site) do
              visit @path

              # byebug
              assert has_selector?("h1", text: "CMS")


              within "tr#collection-item-#{collection.id}" do
                click_link "Site news"
              end

              assert has_selector?("h1", text: "CMS")
              assert_equal admin_common_collection_path(collection.id), current_path

              within "table.pages-list " do #"tr#collection-item-#{collection.id}" do
                click_link "Site news 1"
              end

              fill_in "page_title_translations_en", with: "privacy page updated"
              fill_in "page_slug", with: "privacy-page-updated"
              fill_in "page_published_on", with: chosen_publication_date

              click_button "Update"

              assert has_message?("Page updated successfully")

              assert has_field?("page_slug", with: "privacy-page-updated")
              assert_equal chosen_publication_date.to_s, air_datepicker_field_value(:page_published_on)

              assert_equal(
                "body site news 1",
                find("#page_body_translations_en", visible: false).value
              )
            end
          end
        end
      end

      def test_update_page_and_switch_locale
        with_signed_in_admin(admin) do
          with_current_site(site) do

            visit edit_admin_cms_page_path(cms_page, collection_id: collection.id)

            assert_equal "collection_id=#{collection.id}", current_uri_query_params

            switch_locale "ES"

            assert_equal "collection_id=#{collection.id}&locale=es", current_uri_query_params

            switch_locale "EN"
          end
        end
      end

    end
  end
end
