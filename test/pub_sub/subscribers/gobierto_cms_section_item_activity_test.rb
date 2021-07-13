# frozen_string_literal: true

require "test_helper"

class Subscribers::GobiertoCmsSectionItemActivityTest < ActiveSupport::TestCase
  class Event < OpenStruct; end

  IP = "1.2.3.4"

  def site
    @site ||= sites(:madrid)
  end

  def subject
    @subject ||= Subscribers::GobiertoCmsSectionItemActivity.new("activities")
  end

  def section_item
    @section_item ||= gobierto_cms_section_items(:cms_section_madrid_1_item_a)
  end

  def admin
    @admin ||= gobierto_admin_admins(:tony)
  end

  def ip_address
    @ip_address ||= IPAddr.new("1.2.3.4")
  end

  def test_section_item_created_event_handling
    assert_difference "Activity.count" do
      subject.section_item_created Event.new(name: "activities/gobierto_cms_section_items.section_item_created", payload: {
                                             subject: section_item, author: admin, ip: IP, site_id: site.id
                                             })
    end

    activity = Activity.last
    assert_equal section_item, activity.subject
    assert_equal admin, activity.author
    assert_equal ip_address, activity.subject_ip
    assert_equal "gobierto_cms.section_item_created", activity.action
    assert activity.admin_activity
    assert_equal site.id, activity.site_id
  end

  def test_section_item_deleted_event_handling
    assert_difference "Activity.count" do
      subject.section_item_deleted Event.new(name: "activities/gobierto_cms_sectiones.section_item_deleted", payload: {
                                             subject: section_item, author: admin, ip: IP, site_id: site.id
                                             })
    end

    activity = Activity.last
    assert_equal section_item, activity.subject
    assert_equal admin, activity.author
    assert_equal ip_address, activity.subject_ip
    assert_equal "gobierto_cms.section_item_deleted", activity.action
    assert activity.admin_activity
    assert_equal site.id, activity.site_id
  end
end
