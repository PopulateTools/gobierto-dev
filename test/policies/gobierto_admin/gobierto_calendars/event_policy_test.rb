# frozen_string_literal: true

require 'test_helper'

module GobiertoAdmin
  module GobiertoCalendars
    class EventPolicyTest < ActiveSupport::TestCase

      def madrid
        @madrid ||= sites(:madrid)
      end

      def regular_admin
        @regular_admin ||= gobierto_admin_admins(:tony)
      end

      def manager_admin
        @manager_admin ||= gobierto_admin_admins(:nick)
      end

      def disabled_admin
        @disabled_admin ||= gobierto_admin_admins(:podrick)
      end

      def active_person_active_event
        @active_person_active_event ||= gobierto_calendars_events(:nelson_tomorrow)
      end
      alias person_event active_person_active_event
      alias event active_person_active_event

      def process_event
        @process_event = gobierto_calendars_events(:richard_published)
      end

      def subject
        @subject ||= GobiertoAdmin::GobiertoCalendars::EventPolicy
      end

      def test_manager_admin_manage?
        assert subject.new(current_admin: manager_admin, event: event, current_site: madrid).manage?
      end

      def test_regular_admin_manage?
        # process event
        assert EventPolicy.new(current_admin: regular_admin, event: process_event, current_site: madrid).manage?

        # person event, with permissions on person
        GobiertoAdmin::GobiertoPeople::PersonPolicy.any_instance.stubs(:manage?).returns(true)
        assert subject.new(current_admin: regular_admin, event: person_event, current_site: madrid).manage?

        # person event, without permissions on person
        GobiertoAdmin::GobiertoPeople::PersonPolicy.any_instance.stubs(:manage?).returns(false)
        refute subject.new(current_admin: regular_admin, event: person_event, current_site: madrid).manage?
      end

      def test_disabled_admin_manage?
        refute subject.new(current_admin: disabled_admin, event: event, current_site: madrid).manage?
      end

      def test_regular_admin_view?
        # assert can view active events on active containers even without permissions
        GobiertoAdmin::GobiertoPeople::PersonPolicy.any_instance.stubs(:manage?).returns(false)
        assert subject.new(current_admin: manager_admin, event: active_person_active_event, current_site: madrid).manage?
      end

    end
  end
end
