# frozen_string_literal: true

require "test_helper"

module GobiertoCommon
  class CollectionTest < ActiveSupport::TestCase
    def site
      @site ||= sites(:madrid)
    end

    def process_collection
      @process_collection ||= gobierto_common_collections(:site_news)
    end

    def page
      @page ||= gobierto_cms_pages(:generic_site_page)
    end

    def person
      @person ||= gobierto_people_people(:richard)
    end

    def create_collection(container, item_type)
      params = { site: site, title: "Title", item_type: item_type }

      if container.is_a? String
        params[:container_type] = container
      else
        params[:container] = container
      end

      Collection.create(params)
    end

    def test_append_in_a_process_collection
      assert_difference "GobiertoCommon::CollectionItem.count", 1 do
        process_collection.append(page)
      end

      assert GobiertoCommon::CollectionItem.exists?(item_id: page.id, item_type: process_collection.item_type, collection: process_collection, container: site)
    end

    def test_update_collection_container_should_update_collection_items
      process_collection.append(page)

      process_collection.container = site
      process_collection.save!

      assert GobiertoCommon::CollectionItem.exists?(item_id: page.id, item_type: process_collection.item_type, collection: process_collection, container: site)
    end

    def test_update_collection_item_type
      process_collection.append(page)

      process_collection.item_type = "GobiertoCms::Page"
      process_collection.save!

      refute GobiertoCommon::CollectionItem.exists?(item_id: page.id, item_type: "GobiertoCms::News", collection: process_collection, container: site)
      assert GobiertoCommon::CollectionItem.exists?(item_id: page.id, item_type: "GobiertoCms::Page", collection: process_collection, container: site)
    end

    def test_to_path
      person_events = create_collection(person, "GobiertoCalendars::Event")

      site_pages = create_collection(site, "GobiertoCms::Page")
      site_news = create_collection(site, "GobiertoCms::News")

      assert_equal "/en/agendas/#{person.slug}", person_events.to_path

      assert_equal "/paginas/#{site_pages.slug}", site_pages.to_path
      assert_equal "/noticias/#{site_news.slug}", site_news.to_path
    end

    def test_public?
      person_events = create_collection(person, "GobiertoCalendars::Event")
      site_pages = create_collection(site, "GobiertoCms::Page")

      assert person_events.public?
      assert site_pages.public?

      person.draft!
      site.draft!

      refute person_events.public?
      assert site_pages.public? # already protected via HTTP auth
    end

  end
end
