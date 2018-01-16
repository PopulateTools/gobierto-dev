# frozen_string_literal: true

require "test_helper"

module GobiertoParticipation
  class ScopeShowTest < ActionDispatch::IntegrationTest
    def setup
      super
      @path = gobierto_participation_scope_path(scope_center.slug)
    end

    def user
      @user ||= users(:peter)
    end

    def site
      @site ||= sites(:madrid)
    end

    def scope_center
      @scope_center ||= gobierto_common_scopes(:center)
    end

    def processes
      @processes ||= site.processes.process.where(scope: scope_center).active
    end

    def groups
      @groups ||= site.processes.group_process.where(scope: scope_center)
    end

    def test_menu_subsections
      with_current_site(site) do
        visit @path

        within ".sub-nav" do
          assert has_content? "Issues"
          assert has_content? "Processes"
        end
      end
    end

    def test_secondary_nav
      with_current_site(site) do
        visit @path

        within "nav.sub-nav menu.secondary_nav" do
          assert has_link? "News"
          assert has_link? "Agenda"
          assert has_link? "Documents"
          assert has_link? "Activity"
        end
      end
    end

    def test_secondary_nav_news
      with_current_site(site) do
        visit @path

        within "nav.sub-nav menu.secondary_nav" do
          click_link "News"
        end

        assert_equal gobierto_participation_scope_pages_path(scope_id: scope_center.slug), current_path

        within "nav.main-nav" do
          assert has_link? "Participation"
        end

        assert has_selector?("h2", text: "News")
      end
    end

    def test_secondary_nav_diary
      with_current_site(site) do
        visit @path

        within "nav.sub-nav menu.secondary_nav" do
          click_link "Agenda"
        end

        assert_equal gobierto_participation_scope_events_path(scope_id: scope_center.slug), current_path

        within "nav.main-nav" do
          assert has_link? "Participation"
        end
      end
    end

    def test_secondary_nav_documents
      with_current_site(site) do
        visit @path

        within "nav.sub-nav menu.secondary_nav" do
          click_link "Documents"
        end

        assert_equal gobierto_participation_scope_attachments_path(scope_id: scope_center.slug), current_path

        within "nav.main-nav" do
          assert has_link? "Participation"
        end

        assert has_selector?("h2", text: "Documents")
      end
    end

    def test_secondary_nav_activity
      with_current_site(site) do
        visit @path

        within "nav.sub-nav menu.secondary_nav" do
          click_link "Activity"
        end

        assert_equal gobierto_participation_scope_activities_path(scope_id: scope_center.slug), current_path

        within "nav.main-nav" do
          assert has_link? "Participation"
        end

        assert has_selector?("h2", text: "Updates")
      end
    end

    def test_subscription_block
      with_javascript do
        with_current_site(site) do
          with_signed_in_user(user) do
            visit @path

            within ".slim_nav_bar" do
              assert has_link? "Follow scope"
            end

            click_on "Follow scope"
            assert has_link? "Scope followed!"

            click_on "Scope followed!"
            assert has_link? "Follow scope"
          end
        end
      end
    end

    def test_process_news
      with_current_site(site) do
        visit @path

        assert_equal scope_center.active_pages.size, all(".place_news-item").size
      end
    end

    def test_scope_with_events
      with_current_site(site) do
        visit @path

        assert_equal scope_center.events.size, all(".place_events-item").size
      end
    end

    def test_scope_processes
      with_current_site(site) do
        visit @path

        assert_equal processes.size, all("div#processes/div").size
      end
    end
  end
end
