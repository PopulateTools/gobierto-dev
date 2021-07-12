# frozen_string_literal: true

require "test_helper"

module GobiertoCore
  class TemplateTest < ActiveSupport::TestCase
    def template
      @template ||= gobierto_core_templates(:application_layout)
    end

    def test_valid
      assert template.valid?
    end
  end
end
