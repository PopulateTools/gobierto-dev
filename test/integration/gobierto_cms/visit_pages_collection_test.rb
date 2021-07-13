# frozen_string_literal: true

require "test_helper"

module GobiertoCms
  class VisitPagesCollectionTest < ActionDispatch::IntegrationTest

    def madrid
      @madrid ||= sites(:madrid)
    end

    def santander
      @santander ||= sites(:santander)
    end

    def santander_cms_collection
      @santander_cms_collection ||= gobierto_common_collections(:santander_cms_pages)
    end



    def madrid_cms_collection
      @participation_collection ||= gobierto_common_collections(:site_pages)
    end

    def madrid_cms_collection_pages
      @participation_collection_pages ||= madrid.pages.where(collection_id: madrid_cms_collection.id).active
    end

    def madrid_cms_collection_page
      @madrid_cms_collection_page ||= madrid_cms_collection_pages.first
    end


    def test_visit_collection
      collection_public_pages = [
        gobierto_cms_pages(:cms_section_l0_p0_page),
        gobierto_cms_pages(:cms_section_l0_p1_page)
      ]

      collection_hidden_pages = [
        gobierto_cms_pages(:cms_section_l0_p2d_page),
        gobierto_cms_pages(:cms_section_l0_p3a_page)
      ]

      with_current_site(santander) do
        visit gobierto_cms_pages_path(santander_cms_collection.slug)

        assert has_content?(santander_cms_collection.title)

        collection_public_pages.each do |page|
          assert has_link?(page.title)
        end

        collection_hidden_pages.each do |page|
          assert has_no_link?(page.title)
        end

        collection_page = collection_public_pages.first

        click_link collection_page.title

        assert has_content?(collection_page.title)
      end
    end

    def test_visit_madrid_cms_collection
      with_current_site(madrid) do
        visit gobierto_cms_pages_path(madrid_cms_collection.slug)

        assert has_content?(madrid_cms_collection.title)

        # check every page into collection have link
        madrid_cms_collection_pages.each do |page|
          assert has_link?(page.title)
        end

        # visit first page
        assert has_content?(madrid_cms_collection_page.title)
        click_link madrid_cms_collection_page.title

        # breadcrumb
        assert has_content?("#{madrid_cms_collection.title} / #{madrid_cms_collection_page.title}")

      end
    end

  end
end
