# frozen_string_literal: true

require "test_helper"

class Subscribers::GobiertoCmsSectionActivityTest < ActiveSupport::TestCase
  class Event < OpenStruct; end

  IP = "1.2.3.4"

  def site
    @site ||= sites(:madrid)
  end

  def subject
    @subject ||= Subscribers::GobiertoCmsSectionActivity.new("activities")
  end

  def section
    @section ||= gobierto_cms_sections(:cms_section_madrid_1)
  end

  def admin
    @admin ||= gobierto_admin_admins(:tony)
  end

  def ip_address
    @ip_address ||= IPAddr.new("1.2.3.4")
  end

  def test_section_created_event_handling
    assert_difference "Activity.count" do
      subject.section_created Event.new(name: "activities/gobierto_cms_sectiones.section_created", payload: {
                                        subject: section, author: admin, ip: IP, site_id: site.id
                                        })
    end

    activity = Activity.last
    assert_equal section, activity.subject
    assert_equal admin, activity.author
    assert_equal ip_address, activity.subject_ip
    assert_equal "gobierto_cms.section_created", activity.action
    assert activity.admin_activity
    assert_equal site.id, activity.site_id
  end

  def test_section_updated_event_handling
    assert_difference "Activity.count" do
      subject.section_updated Event.new(name: "activities/gobierto_cms_sectiones.section_updated", payload: {
                                        subject: section, author: admin, ip: IP, site_id: site.id
                                        })
    end

    activity = Activity.last
    assert_equal section, activity.subject
    assert_equal admin, activity.author
    assert_equal ip_address, activity.subject_ip
    assert_equal "gobierto_cms.section_updated", activity.action
    assert activity.admin_activity
    assert_equal site.id, activity.site_id
  end
end
