# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  module GobiertoCommon
    class CreateCmsPagesCollectionTest < ActionDispatch::IntegrationTest
      def setup
        super
        @path = admin_cms_pages_path
      end

      def admin
        @admin ||= gobierto_admin_admins(:tony)
      end

      def site_santander
        @site_santander ||= sites(:santander)
      end

      def site_madrid
        @site_madrid ||= sites(:madrid)
      end

      def test_create_collection_errors
        with_javascript do
          with_signed_in_admin(admin) do
            with_current_site(site_santander) do
              visit @path

              within "#new-page" do
                click_link "New"
              end

              click_button "Create"

              assert has_alert?("Title can't be blank")
            end
          end
        end
      end

      def test_create_collection
        with_javascript do
          with_signed_in_admin(admin) do
            with_current_site(site_santander) do
              visit @path

              within "#new-page" do
                click_link "New"
              end

              fill_in "collection_title_translations_en", with: "My collection"
              fill_in "collection_slug", with: "my-collection"
              find("select#collection_container_global_id").find("option[value='#{site_santander.to_global_id}']").select_option
              find("select#collection_item_type").find("option[value='GobiertoCms::Page']").select_option

              switch_locale "ES"
              fill_in "collection_title_translations_es", with: "Mi colección"

              click_button "Create"

              assert has_message?("Collection was successfully created.")

              assert has_selector?("h1", text: "My collection")

              collection = site_santander.collections.last
              activity = Activity.last
              assert_equal collection, activity.subject
              assert_equal admin, activity.author
              assert_equal site_santander.id, activity.site_id
              assert_equal "gobierto_common.collection_created", activity.action
            end
          end
        end
      end

      def test_create_collection_with_same_container
        with_javascript do
          with_signed_in_admin(admin) do
            with_current_site(site_madrid) do
              visit @path

              within "#new-page" do
                click_link "New"
              end

              fill_in "collection_title_translations_en", with: "My collection"
              find("select#collection_container_global_id").find("option[value='#{site_madrid.to_global_id}']").select_option
              find("select#collection_item_type").find("option[value='GobiertoCms::News']").select_option

              click_button "Create"

              visit @path

              within "#new-page" do
                click_link "New"
              end

              fill_in "collection_title_translations_en", with: "My collection"
              find("select#collection_container_global_id").find("option[value='#{site_madrid.to_global_id}']").select_option
              find("select#collection_item_type").find("option[value='GobiertoCms::News']").select_option

              click_button "Create"

              assert has_content?("Container can't have another collection of this type")
            end
          end
        end
      end
    end
  end
end
