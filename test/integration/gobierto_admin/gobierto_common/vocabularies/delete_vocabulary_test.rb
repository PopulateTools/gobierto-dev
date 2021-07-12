# frozen_string_literal: true

require "test_helper"

module GobiertoCommon
  module GobiertoAdmin
    module Vocabularies
      class DeleteVocabularyTest < ActionDispatch::IntegrationTest

        def setup
          super
          @path = admin_common_vocabularies_path
        end

        def admin
          @admin ||= gobierto_admin_admins(:tony)
        end

        def unauthorized_admin
          @unauthorized_admin ||= gobierto_admin_admins(:steve)
        end

        def site
          @site ||= sites(:madrid)
        end

        def vocabulary
          @vocabulary ||= gobierto_common_vocabularies(:animals)
        end

        def vocabulary_with_associated_items
          @vocabulary_with_associated_items ||= gobierto_common_vocabularies(:madrid_political_groups_vocabulary)
        end

        def test_permissions
          with_signed_in_admin(unauthorized_admin) do
            with_current_site(site) do
              visit @path
              assert has_content?("You are not authorized to perform this action")
              assert_equal edit_admin_admin_settings_path, current_path
            end
          end
        end

        def test_delete_vocabulary
          with_signed_in_admin(admin) do
            with_current_site(site) do
              visit @path

              within "#vocabulary-item-#{vocabulary.id}" do
                find("a[data-method='delete']").click
              end

              assert has_message?("Vocabulary deleted successfully.")

              refute site.vocabularies.exists?(id: vocabulary.id)
            end
          end
        end

        def test_delete_vocabulary_with_associated_items
          with_signed_in_admin(admin) do
            with_current_site(site) do
              visit @path

              within "#vocabulary-item-#{vocabulary_with_associated_items.id}" do
                find("a[data-method='delete']").click
              end

              assert has_message?("Vocabulary couldn't be deleted because it's being used")

              assert site.vocabularies.exists?(id: vocabulary_with_associated_items.id)
            end
          end
        end
      end
    end
  end
end
