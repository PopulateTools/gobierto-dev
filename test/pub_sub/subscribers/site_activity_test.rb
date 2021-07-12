# frozen_string_literal: true

require "test_helper"

class Subscribers::SiteActivityTest < ActiveSupport::TestCase
  class Event < OpenStruct; end

  IP = "1.2.3.4"

  def site
    @site ||= sites(:madrid)
  end

  def subject
    @subject ||= Subscribers::SiteActivity.new("activities")
  end

  def admin
    @admin ||= gobierto_admin_admins(:tony)
  end

  def ip_address
    @ip_address ||= IPAddr.new("1.2.3.4")
  end

  def configuration_data_modules_updated
    {
      "configuration_data" => [
        {
          "modules" => ["", "GobiertoBudgets"],
          "google_analytics_id" => "UA-000000-02",
          "foot_markup" => ""
        },
        {
          "modules" => ["", "GobiertoDevelopment", "GobiertoBudgets"],
          "google_analytics_id" => "UA-000000-03",
          "foot_markup" => ""
        }
      ]
    }
  end

  def test_site_created_event_handling
    assert_difference "Activity.count" do
      subject.site_created Event.new(name: "activities/sites.site_created", payload: {
                                       subject: site, author: admin, ip: IP
                                     })
    end

    activity = Activity.last
    assert_equal site, activity.subject
    assert_equal admin, activity.author
    assert_equal ip_address, activity.subject_ip
    assert_equal "sites.site_created", activity.action
    assert activity.admin_activity
    assert_nil activity.site_id
  end

  def test_site_updated_event_handling_for_empty_changes
    assert_no_difference "Activity.count" do
      subject.site_updated Event.new(name: "activities/sites.site_updated", payload: {
                                       subject: site, author: admin, ip: IP,
                                       changes: {}
                                     })
    end
  end

  def test_site_updated_event_handling_for_site_updated_activity
    assert_difference "Activity.count" do
      subject.site_updated Event.new(name: "activities/sites.site_updated", payload: {
                                       subject: site, author: admin, ip: IP,
                                       changes: { "name" => ["Ayuntamiento de Madrid", "Ayuntamiento de los Madriles"] }
                                     })
    end

    activity = Activity.last
    assert_equal site, activity.subject
    assert_equal admin, activity.author
    assert_equal ip_address, activity.subject_ip
    assert_equal "sites.site_updated", activity.action
    assert activity.admin_activity
    assert_nil activity.site_id
  end

  def test_site_updated_event_handling_for_site_visibility_updated_activity
    assert_difference "Activity.count" do
      subject.site_updated Event.new(name: "activities/sites.site_updated", payload: {
                                       subject: site, author: admin, ip: IP,
                                       changes: { "visibility_level" => %w(active draft) }
                                     })
    end

    activity = Activity.last
    assert_equal site, activity.subject
    assert_equal admin, activity.author
    assert_equal ip_address, activity.subject_ip
    assert_equal "sites.site_visibility_updated", activity.action
    assert activity.admin_activity
    assert_nil activity.site_id
  end

  def test_site_updated_event_handling_for_site_modules_updated_activity
    assert_difference "Activity.count" do
      subject.site_updated Event.new(name: "activities/sites.site_updated", payload: {
                                       subject: site, author: admin, ip: IP,
                                       changes: configuration_data_modules_updated
                                     })
    end

    activity = Activity.last
    assert_equal site, activity.subject
    assert_equal admin, activity.author
    assert_equal ip_address, activity.subject_ip
    assert_equal "sites.site_modules_updated", activity.action
    assert activity.admin_activity
    assert_nil activity.site_id
  end

  def test_site_updated_event_handling_for_multiple_changes
    last_activity_id = Activity.maximum(:id)
    assert_difference "Activity.count", 3 do
      subject.site_updated Event.new(name: "activities/sites.site_updated", payload: {
                                       subject: site, author: admin, ip: IP,
                                       changes: {
                                         "visibility_level" => %w(active draft),
                                         "name" => ["Ayuntamiento de Madrid", "Ayuntamiento de los Madriles"],
                                         "configuration_data" => configuration_data_modules_updated["configuration_data"]
                                       }
                                     })
    end

    last_activities_action = Activity.where("id > ?", last_activity_id).pluck(:action)
    assert_includes last_activities_action, "sites.site_visibility_updated"
    assert_includes last_activities_action, "sites.site_updated"
    assert_includes last_activities_action, "sites.site_modules_updated"
  end

  def test_site_deleted_event_handling

    # manually deassociate terms from items, so they can be destroyed
    site.people.update_all(political_group_id: nil)
    site.plans.update_all(vocabulary_id: nil)
    GobiertoPlans::Node.update_all(status_id: nil)
    site.services.update_all(category_id: nil)

    assert_difference "Activity.count" do
      site.destroy

      subject.site_deleted Event.new(name: "activities/sites.site_destroyed", payload: {
                                       subject: site, author: admin, ip: IP
                                     })
    end

    activity = Activity.last

    assert_nil activity.subject
    assert_equal admin, activity.author
    assert_equal ip_address, activity.subject_ip
    assert_equal "sites.site_destroyed", activity.action
    assert activity.admin_activity
    assert_nil activity.site_id
  end
end
