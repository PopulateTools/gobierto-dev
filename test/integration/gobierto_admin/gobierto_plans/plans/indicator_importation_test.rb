require "test_helper"

module GobiertoAdmin
  module GobiertoPlans
    class IndicatorImportationTest < ActionDispatch::IntegrationTest
      include Integration::AdminGroupsConcern

      attr_reader :plan, :path

      def setup
        super
        @path = edit_admin_plans_plan_path(plan.id)
      end

      def site
        @site ||= sites(:madrid)
      end

      def admin
        @admin ||= gobierto_admin_admins(:nick)
      end

      def plan
        @plan ||= gobierto_plans_plans(:multiple_indicators_plan)
      end

      def test_import_indicators_from_csv__adding_more_records
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit path

            assert has_content? "Import from CSV"
            click_on "Import from CSV"

            assert has_content? "Custom fields (table plugin)"

            attach_file "file_csv_file", Rails.root.join("test/fixtures/files/gobierto_plans/indicators-plan-updated.csv")
            within "form.new_file" do
              with_stubbed_s3_file_upload do
                click_button "Import from CSV file"
              end
            end

            within ".flash-message", match: :first do
              assert has_content? "Data imported successfully"
            end

            records_after_import = plan.indicators.map(&:payload).map(&:values).flatten.size
            assert_equal 12, records_after_import
          end
        end
      end

    end
  end
end
