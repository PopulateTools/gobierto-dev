# frozen_string_literal: true

module GobiertoCms
  module PageHelper

    # TODO - Refactor
    def section_tree(nodes, viewables)
      html = ["<ul>"]
      nodes.each do |node|
        html << "<li>" + link_to(node.item.title, gobierto_cms_section_item_path(@section.slug, node.item.slug))
        # TODO - This conditions are not fully tested and are too complex for a view helper
        if node.children.any? && !(viewables & node.children).empty?
          html << section_tree(node.children.not_archived.not_drafted, viewables)
        end
        html << "</li>"
      end
      html << "</ul>"
      html.join.html_safe
    end

    def gobierto_cms_page_or_news_path(page, options = {})
      url_helpers = Rails.application.routes.url_helpers

      if page.collection&.item_type == "GobiertoCms::Page"
        section = page.section
        if section
          url_helpers.gobierto_cms_section_item_path(section.slug, page.slug, options)
        else
          url_helpers.gobierto_cms_page_path(page.slug, options)
        end
      elsif page.collection&.item_type == "GobiertoCms::News"
        url_helpers.gobierto_cms_news_path(page.slug, options)
      end
    end
  end
end
