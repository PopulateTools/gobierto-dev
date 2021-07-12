# frozen_string_literal: true

require "test_helper"

class Subscribers::GobiertoCommonCollectionActivityTest < ActiveSupport::TestCase
  class Event < OpenStruct; end

  IP = "1.2.3.4"

  def site
    @site ||= sites(:madrid)
  end

  def subject
    @subject ||= Subscribers::GobiertoCommonCollectionActivity.new("activities")
  end

  def collection
    @collection ||= gobierto_common_collections(:site_news)
  end

  def admin
    @admin ||= gobierto_admin_admins(:tony)
  end

  def ip_address
    @ip_address ||= IPAddr.new("1.2.3.4")
  end

  def test_collection_created_event_handling
    assert_difference "Activity.count" do
      subject.collection_created Event.new(name: "activities/gobierto_common_collections.collection_created", payload: {
                                             subject: collection, author: admin, ip: IP, site_id: site.id
                                           })
    end

    activity = Activity.last
    assert_equal collection, activity.subject
    assert_equal admin, activity.author
    assert_equal ip_address, activity.subject_ip
    assert_equal "gobierto_common.collection_created", activity.action
    assert activity.admin_activity
    assert_equal site.id, activity.site_id
  end

  def test_collection_updated_event_handling
    assert_difference "Activity.count" do
      subject.collection_updated Event.new(name: "activities/gobierto_common_collections.collection_updated", payload: {
                                             subject: collection, author: admin, ip: IP, site_id: site.id
                                           })
    end

    activity = Activity.last
    assert_equal collection, activity.subject
    assert_equal admin, activity.author
    assert_equal ip_address, activity.subject_ip
    assert_equal "gobierto_common.collection_updated", activity.action
    assert activity.admin_activity
    assert_equal site.id, activity.site_id
  end
end
