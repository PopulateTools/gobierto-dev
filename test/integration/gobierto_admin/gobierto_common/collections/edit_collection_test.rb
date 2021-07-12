# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  module GobiertoCommon
    module Collections
      class ShowCollectionTest < ActionDispatch::IntegrationTest

        def site
          @site ||= sites(:madrid)
        end

        def admin
          @admin ||= gobierto_admin_admins(:nick)
        end

        def collection
          @collection ||= gobierto_common_collections(:site_attachments)
        end

        def test_edit_collection
          with_signed_in_admin(admin) do
            with_current_site(site) do
              visit edit_admin_common_collection_path(collection)

              assert has_content?(collection.container.title)
            end
          end
        end

      end
    end
  end
end
