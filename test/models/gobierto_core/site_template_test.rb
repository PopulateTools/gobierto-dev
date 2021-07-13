# frozen_string_literal: true

require "test_helper"

module GobiertoCore
  class SiteTemplateTest < ActiveSupport::TestCase
    def site_template
      @site_template ||= gobierto_core_site_templates(:cortegada_site_template_index)
    end

    def test_valid
      assert site_template.valid?
    end
  end
end
