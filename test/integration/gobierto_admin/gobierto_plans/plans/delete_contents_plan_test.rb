# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  module GobiertoPlans
    class DeleteContentsPlanTest < ActionDispatch::IntegrationTest
      include Integration::AdminGroupsConcern

      attr_reader :plan, :path

      def setup
        super
        @plan = gobierto_plans_plans(:strategic_plan)
        @path = edit_admin_plans_plan_path(plan)
      end

      def admin
        @admin ||= gobierto_admin_admins(:nick)
      end

      def site
        @site ||= sites(:madrid)
      end

      def custom_field_vocabulary
        @custom_field_vocabulary ||= gobierto_common_vocabularies(:animals)
      end

      def vocabulary_used_in_other_context
        @vocabulary_used_in_other_context ||= gobierto_common_vocabularies(:madrid_political_groups_vocabulary)
      end

      def statuses_vocabulary
        @statuses_vocabulary ||= gobierto_common_vocabularies(:plan_projects_statuses_vocabulary)
      end

      def status_term
        @status_term ||= gobierto_common_terms(:not_started_plan_status_term)
      end

      def test_delete_contents
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit path

            click_link "Delete projects of this plan"

            assert has_message? "Plan projects has been successfully deleted"

            assert plan.nodes.blank?
            assert plan.categories_vocabulary.terms.blank?
            assert custom_field_vocabulary.terms.blank?
            assert statuses_vocabulary.terms.blank?
          end
        end
      end

      def test_delete_contents_with_other_empty_plan_with_same_statuses_vocabulary
        site.plans.create(plan.attributes.slice("title_translations", "introduction_translations", "plan_type_id", "statuses_vocabulary_id").merge(year: plan.year + 1))
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit path

            click_link "Delete projects of this plan"

            assert has_message? "Plan projects has been successfully deleted"
          end
        end
      end

      def test_delete_contents_with_other_not_empty_plan_with_same_statuses_vocabulary
        new_plan = site.plans.create(
          plan.attributes.slice(
            "title_translations",
            "introduction_translations",
            "plan_type_id",
            "statuses_vocabulary_id"
          ).merge(year: plan.year + 1)
        )
        new_node = new_plan.nodes.create(name: "Wadus", status: status_term, external_id: "wadus")
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit path

            click_link "Delete projects of this plan"

            assert has_alert? "The term \"#{status_term.name}\" of \"#{statuses_vocabulary.name}\" vocabulary can't be deleted"
            assert has_alert? "GobiertoPlans::Node: Attribute status_id on instances with ids #{new_node.id}"
          end
        end
      end

      def test_delete_contents_with_vocabulary_used_in_other_context
        plan.update_attribute(:statuses_vocabulary_id, vocabulary_used_in_other_context.id)
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit path

            click_link "Delete projects of this plan"

            assert has_alert?(/The term \".*\" of \"#{vocabulary_used_in_other_context.name}\" vocabulary can't be deleted/)
            assert has_alert? "GobiertoPeople::Person: Attribute political_group_id on instances with ids"
          end
        end
      end
    end
  end
end
