# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  class SitesControllerTest < GobiertoControllerTest
    def setup
      super
      @notification_service_spy = Spy.on(Publishers::SiteActivity, :broadcast_event)
    end

    attr_reader :notification_service_spy

    def admin
      @admin ||= gobierto_admin_admins(:natasha)
    end

    def regular_admin_with_customize_permissions
      @regular_admin_with_customize_permissions ||= gobierto_admin_admins(:tony)
    end

    def regular_admin
      @regular_admin ||= gobierto_admin_admins(:steve)
    end

    def site
      @site ||= sites(:madrid)
    end

    def valid_site_params
      {
        title_translations: { I18n.locale => "Title" },
        name_translations: { I18n.locale => "Foo" },
        organization_name: "Madrid",
        organization_id: "1",
        domain: "test2.gobierto.test",
        visibility_level: "active",
        home_page: "GobiertoBudgets"
      }
    end

    def site
      @site ||= sites(:madrid)
    end

    def test_index
      with_current_site(site) do
        with_signed_in_admin(admin) do
          get admin_sites_url
          assert_response :success
        end
      end
    end

    def test_index_not_authorized
      with_current_site(site) do
        with_signed_in_admin(regular_admin) do
          get admin_sites_url
          assert_redirected_to admin_root_path
        end

        with_signed_in_admin(regular_admin_with_customize_permissions) do
          get admin_sites_url
          assert_redirected_to admin_root_path
        end
      end
    end

    def test_new
      with_current_site(site) do
        with_signed_in_admin(admin) do
          get new_admin_site_url
          assert_response :success
        end
      end
    end

    def test_new_not_authorized
      with_current_site(site) do
        with_signed_in_admin(regular_admin) do
          get new_admin_site_url
          assert_redirected_to admin_root_path
        end

        with_signed_in_admin(regular_admin_with_customize_permissions) do
          get new_admin_site_url
          assert_redirected_to admin_root_path
        end
      end
    end

    def test_edit
      with_current_site(site) do
        with_signed_in_admin(admin) do
          get edit_admin_site_url(site)
          assert_response :success
        end

        with_signed_in_admin(regular_admin_with_customize_permissions) do
          get edit_admin_site_url(site)
          assert_response :success
        end
      end
    end

    def test_edit_not_authorized
      with_current_site(site) do
        with_signed_in_admin(regular_admin) do
          get edit_admin_site_url(site)
          assert_redirected_to admin_root_path
        end
      end
    end

    def test_create
      with_current_site(site) do
        with_signed_in_admin(admin) do
          post admin_sites_url, params: { site: valid_site_params }
          assert_redirected_to admin_sites_path
        end
      end
    end

    def test_create_not_authorized
      with_current_site(site) do
        with_signed_in_admin(regular_admin) do
          post admin_sites_url, params: { site: valid_site_params }
          assert_redirected_to admin_root_path
        end

        with_signed_in_admin(regular_admin_with_customize_permissions) do
          post admin_sites_url, params: { site: valid_site_params }
          assert_redirected_to admin_root_path
        end
      end
    end

    def test_update
      with_current_site(site) do
        with_signed_in_admin(admin) do
          patch admin_site_url(site), params: { site: valid_site_params }
          assert_redirected_to edit_admin_site_path(site)
        end

        with_signed_in_admin(regular_admin_with_customize_permissions) do
          patch admin_site_url(site), params: { site: valid_site_params }
          assert_redirected_to edit_admin_site_path(site)
        end
      end
    end

    def test_update_not_authorized
      with_current_site(site) do
        with_signed_in_admin(regular_admin) do
          patch admin_site_url(site), params: { site: valid_site_params }
          assert_redirected_to admin_root_path
        end
      end
    end

    def test_destroy
      with_current_site(site) do
        with_signed_in_admin(admin) do
          delete admin_site_url(site)
          assert_redirected_to admin_sites_path
        end
      end
    end

    def test_destroy_not_authorized
      with_current_site(site) do
        with_signed_in_admin(regular_admin) do
          delete admin_site_url(site)
          assert_redirected_to admin_root_path
        end

        with_signed_in_admin(regular_admin_with_customize_permissions) do
          delete admin_site_url(site)
          assert_redirected_to admin_root_path
        end
      end
    end

    def first_call_arguments
      notification_service_spy.calls.first.args
    end

    def test_create_site_broadcasts_event
      with_current_site(site) do
        with_signed_in_admin(admin) do
          post admin_sites_url, params: { site: valid_site_params }
          assert_response :redirect

          assert notification_service_spy.has_been_called?
          event_name, event_payload = first_call_arguments
          assert_equal "site_created", event_name
          assert_includes event_payload, :ip
          assert_equal event_payload[:author], admin
          assert_equal event_payload[:subject], Site.last
          refute event_payload.include?(:changes)
        end
      end
    end

    def test_update_site_broadcasts_event
      with_current_site(site) do
        with_signed_in_admin(admin) do
          patch admin_site_url(site), params: { site: valid_site_params }
          assert_response :redirect

          assert notification_service_spy.has_been_called?
          event_name, event_payload = first_call_arguments
          assert_equal "site_updated", event_name
          assert_includes event_payload, :ip
          assert_equal event_payload[:author], admin
          assert_equal event_payload[:subject], site
          assert event_payload.include?(:changes)
        end
      end
    end

    def test_update_site_with_invalid_params_doesnt_broadcasts_event
      with_current_site(site) do
        with_signed_in_admin(admin) do
          patch admin_site_url(site), params: { site: { name: "" } }
          assert_response :success

          refute notification_service_spy.has_been_called?
        end
      end

      def test_destroy_site_broadcasts_event
        with_current_site(site) do
          with_signed_in_admin(admin) do
            delete admin_site_url(site)
            assert_response :redirect

            assert notification_service_spy.has_been_called?
            event_name, event_payload = first_call_arguments
            assert_equal "site_deleted", event_name
            assert_includes event_payload, :ip
            assert_equal event_payload[:author], admin
            assert_equal event_payload[:subject], site
          end
        end
      end
    end
  end
end
