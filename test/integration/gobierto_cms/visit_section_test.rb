# frozen_string_literal: true

require "test_helper"

module GobiertoCms
  class VisitSectionTest < ActionDispatch::IntegrationTest

    def setup
      super
      @path = gobierto_cms_section_path(section.slug)
    end

    def site
      @site ||= sites(:santander)
    end

    def section
      @section ||= gobierto_cms_sections(:cms_pages_santander)
    end

    def section_public_pages
      @section_public_pages ||= [
        gobierto_cms_pages(:cms_section_l0_p0_page),
        gobierto_cms_pages(:cms_section_l0_p1_page)
      ]
    end

    def section_draft_page
      @section_draft_page ||= gobierto_cms_pages(:cms_section_l0_p2d_page)
    end

    def section_archived_page
      @section_archived_page ||= gobierto_cms_pages(:cms_section_l0_p3a_page)
    end

    def section_page
      section_public_pages.first
    end

    def test_visit_section
      with_current_site(site) do
        visit @path

        assert has_content?(section.title)

        section_public_pages.each do |page|
          assert has_link?(page.title)
        end

        assert has_no_link?(section_archived_page.title)
        assert has_no_link?(section_draft_page.title)

        click_link section_page.title

        assert has_content?(section_page.title)
        assert has_content?(section.title)
      end
    end

    def test_visit_section_when_first_page_is_draft
      first_page = section_public_pages.first
      second_page = section_public_pages.second

      first_page.draft!

      with_current_site(site) do
        visit @path

        assert has_selector?("h1", text: second_page.title)
      end
    end

    def test_visit_section_when_first_page_is_archived
      first_page = section_public_pages.first
      second_page = section_public_pages.second

      first_page.archive

      with_current_site(site) do
        visit @path

        assert has_selector?("h1", text: second_page.title)
      end
    end

    def test_visit_section_when_no_public_pages
      section_public_pages.each(&:archive)

      with_current_site(site) do
        visit @path

        assert_equal "/", current_path
      end
    end

    def test_list_children_pages
      with_current_site(site) do
        public_children_pages = [
          gobierto_cms_pages(:cms_section_l1_p0p0_page),
          gobierto_cms_pages(:cms_section_l1_p0p1_page)
        ]
        hidden_children_pages = [
          gobierto_cms_pages(:cms_section_l1_p0p2d_page),
          gobierto_cms_pages(:cms_section_l1_p0p3a_page)
        ]

        visit @path

        public_children_pages.each do |page|
          assert has_link?(page.title)
        end

        hidden_children_pages.each do |page|
          assert has_no_link?(page.title)
        end
      end
    end

    def test_visit_section_with_right_and_wrong_page
      with_current_site(site) do
        other_section = gobierto_cms_sections(:other_section_santander)
        other_page = gobierto_cms_pages(:other_page_for_other_section)

        cms_page = gobierto_cms_pages(:cms_section_l0_p0_page)

        get gobierto_cms_section_item_path(slug_section: other_section.slug, id: other_page.slug)
        assert_response :success

        get gobierto_cms_section_item_path(slug_section: other_section.slug, id: cms_page.slug)
        assert_response :not_found
      end
    end

  end
end
