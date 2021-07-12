# frozen_string_literal: true

require "test_helper"

class SectionTest < ActiveSupport::TestCase
  def section
    @section ||= gobierto_cms_sections(:cms_section_madrid)
  end

  def test_valid
    assert section.valid?
  end
end
