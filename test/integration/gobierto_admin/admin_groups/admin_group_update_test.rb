# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  class AdminGroupUpdateTest < ActionDispatch::IntegrationTest

    def madrid_group
      @madrid_group ||= gobierto_admin_admin_groups(:madrid_group)
    end

    def manager_admin
      @manager_admin ||= gobierto_admin_admins(:nick)
    end

    def regular_admin
      @regular_admin ||= gobierto_admin_admins(:tony)
    end

    def site
      @site ||= sites(:madrid)
    end

    def richard
      @richard ||= gobierto_people_people(:richard)
    end

    def neil
      @neil ||= gobierto_people_people(:neil)
    end

    def test_admin_group_update
      with_javascript do
        with_current_site(site) do
          with_signed_in_admin(manager_admin) do
            visit edit_admin_admin_group_path(madrid_group)

            within "form.edit_admin_group" do
              fill_in "admin_group_name", with: "Admin Group changed name"

              find("label[for='admin_group_site_options_vocabularies']").click
              find("label[for='admin_group_site_options_templates']").click

              click_button "Update"
            end

            assert has_message?("Admins Group was successfully updated")

            within "form.edit_admin_group" do
              assert has_field?("admin_group_name", with: "Admin Group changed name")
              refute find("#admin_group_modules_gobiertobudgets", visible: false).checked?
              refute find("#admin_group_site_options_vocabularies", visible: false).checked?
              assert find("#admin_group_site_options_templates", visible: false).checked?
            end
          end
        end
      end
    end

    def test_admin_group_update_with_custom_permissions
      with_current_site(site) do
        with_signed_in_admin(manager_admin) do
          visit edit_admin_admin_group_path(madrid_group)

          within "form.edit_admin_group" do
            fill_in "admin_group_name", with: "Admin Group changed name"

            check "Gobierto People"
            check "Neil Patrick"
            uncheck "Richard Rider"

            click_button "Update"
          end

          assert has_message?("Admins Group was successfully updated")

          within "form.edit_admin_group" do
            assert has_field?("admin_group_name", with: "Admin Group changed name")
            assert has_checked_field?("Gobierto People")
            assert has_no_checked_field?("All")
            assert has_checked_field?("Neil Patrick")
            assert has_no_checked_field?("Richard Rider")
          end
        end
      end
    end

    def test_admin_group_update_with_custom_permissions_all
      with_javascript do
        with_current_site(site) do
          with_signed_in_admin(manager_admin) do
            visit edit_admin_admin_group_path(madrid_group)

            within "form.edit_admin_group" do
              fill_in "admin_group_name", with: "Admin Group changed name"

              find("label[for='admin_group_all_people']").click

              click_button "Update"
            end

            assert has_message?("Admins Group was successfully updated")

            within "form.edit_admin_group" do
              assert has_field?("admin_group_name", with: "Admin Group changed name")
              assert find("#admin_group_modules_gobiertopeople", visible: false).checked?
              assert find("#admin_group_all_people", visible: false).checked?
              refute find("#admin_group_people_#{neil.id}", visible: false).checked?
              refute find("#admin_group_people_#{richard.id}", visible: false).checked?
            end
          end
        end
      end
    end

    def test_admin_group_update_with_custom_actions_moderate
      with_javascript do
        with_current_site(site) do
          with_signed_in_admin(manager_admin) do
            visit edit_admin_admin_group_path(madrid_group)

            within "form.edit_admin_group" do
              find("label[for='admin_group_modules_gobiertoplans']").click
              find("label[for='modules_action_gobierto_plans_moderate']").click
              find("label[for='modules_action_gobierto_plans_manage']").click
              find("label[for='admin_group_all_people']").click

              click_button "Update"
            end

            assert has_message?("Admins Group was successfully updated")

            within "form.edit_admin_group" do
              assert find("#admin_group_modules_gobiertopeople", visible: false).checked?
              refute find("#modules_action_gobierto_plans_manage", visible: false).checked?
              refute find("#modules_action_gobierto_plans_edit", visible: false).checked?
              assert find("#modules_action_gobierto_plans_moderate", visible: false).checked?
              assert find("#admin_group_all_people", visible: false).checked?
              refute find("#admin_group_people_#{neil.id}", visible: false).checked?
              refute find("#admin_group_people_#{richard.id}", visible: false).checked?
            end

            assert_equal 12, madrid_group.permissions.count
            assert GobiertoAdmin::Permission::GobiertoPlans.where(admin_group: madrid_group, action_name: "moderate").exists?
            assert madrid_group.permissions.for_people.where(action_name: "manage_all").exists?
          end
        end
      end
    end

    def test_regular_admin_create
      with_current_site(site) do
        with_signed_in_admin(regular_admin) do
          visit edit_admin_admin_group_path(madrid_group)

          assert has_no_selector?("form.edit_admin_group")
        end
      end
    end
  end
end
