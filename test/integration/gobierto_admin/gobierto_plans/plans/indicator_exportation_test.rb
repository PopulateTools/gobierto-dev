require "test_helper"

module GobiertoAdmin
  module GobiertoPlans
    class IndicatorsCreationTest < ActionDispatch::IntegrationTest
      include Integration::AdminGroupsConcern

      attr_reader :path_with_indicators, :path_without_indicators

      def setup
        @path_with_indicators = edit_admin_plans_plan_path(id: plan_with_indicators)
        @path_without_indicators = edit_admin_plans_plan_path(id: plan_without_indicators)
      end

      def admin
        @admin ||= gobierto_admin_admins(:nick)
      end

      def site
        @site ||= sites(:madrid)
      end

      def plan_with_indicators
        @plan_with_indicators ||= gobierto_plans_plans(:dashboards_plan)
      end

      def plan_without_indicators
        @plan_without_indicators ||= gobierto_plans_plans(:government_plan)
      end

      def test_download_indicator_from_project_without_indicators_in_plan
        with_signed_in_admin(admin) do
          with_current_site(site) do

            visit path_with_indicators

            within ".admin_side_actions" do
              assert has_content? "Indicators"
            end
            # test payload after click are into decorator
          end
        end
      end

      def test_download_indicators_from_project_with_indicators_in_plan
        with_signed_in_admin(admin) do
          with_current_site(site) do

            visit path_without_indicators

            within ".admin_side_actions" do
              refute has_content? "Indicators"
            end
            # test payload after click are into decorator
          end
        end
      end

    end
  end
end
