# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  module GobiertoPlans
    class ImportCsvPlanTest < ActionDispatch::IntegrationTest
      include Integration::AdminGroupsConcern

      attr_reader :plan, :path, :statuses_vocabulary

      def setup
        super
        @statuses_vocabulary = gobierto_common_vocabularies(:plan_csv_import_statuses_vocabulary)
        @plan = gobierto_plans_plans(:strategic_plan)
        @plan.update_attribute(:statuses_vocabulary_id, statuses_vocabulary.id)
        @path = edit_admin_plans_plan_path(plan)
      end

      def admin
        @admin ||= gobierto_admin_admins(:nick)
      end

      def site
        @site ||= sites(:madrid)
      end

      def node
        @node ||= gobierto_plans_nodes(:scholarships_kindergartens)
      end

      def table_custom_field_indicators
        @table_custom_field_indicators ||= gobierto_common_custom_fields(:madrid_custom_field_indicators_table_plugin)
      end

      def table_custom_field_directory
        @table_custom_field_directory ||= gobierto_common_custom_fields(:madrid_custom_field_table_plugin)
      end

      def vocabulary_used_in_other_context
        @vocabulary_used_in_other_context ||= gobierto_common_vocabularies(:madrid_political_groups_vocabulary)
      end

      def blank_status_term
        @blank_status_term ||= gobierto_common_terms(:blank_imported_plan_status_term)
      end

      def test_import_csv_without_file
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit path

            click_link "Import from CSV"

            within "form.new_plan" do
              click_button "Import from CSV file"
            end

            assert has_alert? "Please, choose a file for the import."
          end
        end
      end

      def test_import_csv_file_without_automatic_publication
        plan.nodes.each(&:destroy)
        with(site: site, admin: admin) do
          visit path

          click_link "Import from CSV"

          attach_file "plan_csv_file", Rails.root.join("test/fixtures/files/gobierto_plans/plan2.csv")
          within "form.new_plan" do
            with_stubbed_s3_file_upload do
              click_button "Import from CSV file"
            end
          end

          within ".flash-message", match: :first do
            assert has_content? "Data imported successfully"
          end

          assert has_content? "5 axes"
          assert has_content? "39 lines of action"
          assert has_content? "119 actions"
          assert has_content? "247 projects/actions"

          plan.reload
          plan.nodes.reload
          assert_equal 247, plan.nodes.count
          assert_equal 0, plan.nodes.published.count

          visit edit_admin_plans_plan_project_path(plan, plan.nodes.first)
          assert has_link? "Permissions"
        end
      end

      def test_import_csv_file_with_automatic_publication
        plan.nodes.each(&:destroy)
        plan.update_attribute(:publish_last_version_automatically, true)
        with(site: site, admin: admin) do
          visit path

          click_link "Import from CSV"

          attach_file "plan_csv_file", Rails.root.join("test/fixtures/files/gobierto_plans/plan2.csv")
          within "form.new_plan" do
            with_stubbed_s3_file_upload do
              click_button "Import from CSV file"
            end
          end

          within ".flash-message", match: :first do
            assert has_content? "Data imported successfully"
          end

          assert has_content? "5 axes"
          assert has_content? "39 lines of action"
          assert has_content? "119 actions"
          assert has_content? "247 projects/actions"

          plan.reload
          assert_equal 247, plan.nodes.count
          assert_equal 247, plan.nodes.published.count
          assert_equal "eix-1-economia-emprenedoria-i-ocupacio", plan.categories_vocabulary.terms.first.slug
          assert_equal 1, plan.nodes.where(status: blank_status_term).count
        end

        with(site: site, js: true) do
          visit gobierto_plans_plan_path(slug: plan.plan_type.slug, year: plan.year)

          assert has_content? "5 axes"
          assert has_content? "39 lines of action"
          assert has_content? "119 actions"
          assert has_content? "247 projects/actions"
        end
      end

      def test_import_csv_file_without_vocabulary
        plan.update_attribute(:statuses_vocabulary_id, nil)
        plan.nodes.each(&:destroy)

        with_signed_in_admin(admin) do
          with_current_site(site) do

            visit path

            click_link "Import from CSV"

            attach_file "plan_csv_file", Rails.root.join("test/fixtures/files/gobierto_plans/plan2.csv")
            within "form.new_plan" do
              with_stubbed_s3_file_upload do
                click_button "Import from CSV file"
              end
            end

            assert has_alert? "The state on the row has not been found in the corresponding statuses vocabulary"
          end
        end
      end

      def test_import_csv_file_with_status_not_present_in_vocabulary
        plan.nodes.each(&:destroy)
        blank_status_term.destroy

        with_signed_in_admin(admin) do
          with_current_site(site) do

            visit path

            click_link "Import from CSV"

            attach_file "plan_csv_file", Rails.root.join("test/fixtures/files/gobierto_plans/plan2.csv")
            within "form.new_plan" do
              with_stubbed_s3_file_upload do
                click_button "Import from CSV file"
              end
            end

            assert has_alert? "The state on the row has not been found in the corresponding statuses vocabulary"
          end
        end
      end

      def test_import_csv_file_without_statuses_and_not_defined_vocabulary
        plan.update_attribute(:statuses_vocabulary_id, nil)
        plan.nodes.each(&:destroy)

        with_signed_in_admin(admin) do
          with_current_site(site) do

            visit path

            click_link "Import from CSV"

            attach_file "plan_csv_file", Rails.root.join("test/fixtures/files/gobierto_plans/plan_blank_statuses.csv")
            within "form.new_plan" do
              with_stubbed_s3_file_upload do
                click_button "Import from CSV file"
              end
            end

            within ".flash-message", match: :first do
              assert has_content? "Data imported successfully"
            end
          end
        end
      end

      def test_import_csv_table_custom_fields
        with(site: site, admin: admin) do
          visit path

          click_link "Import from CSV"

          attach_file "file_csv_file", Rails.root.join("test/fixtures/files/gobierto_plans/table_custom_fields.csv")
          within "form.new_file" do
            with_stubbed_s3_file_upload do
              click_button "Import from CSV file"
            end
          end

          within ".flash-message", match: :first do
            assert has_content? "Data imported successfully"
          end

          imported_directory = node.custom_field_records.find_by(custom_field: table_custom_field_directory).value

          assert_equal 2, imported_directory.count
          assert_equal "miguel@example.org", imported_directory.first["email"]
          assert_equal 999_999_999, imported_directory.first["phone_number"]

          imported_indicators = node.custom_field_records.find_by(custom_field: table_custom_field_indicators).value

          assert_equal 1, imported_indicators.count
          assert_equal 45.0, imported_indicators.first["objective"]
          assert_equal 23.0, imported_indicators.first["value_reached"]
          assert_equal "2020", imported_indicators.first["date"]
        end
      end

      def test_import_csv_with_prefixed_external_id_column
        with(site: site, admin: admin) do
          visit path

          click_link "Import from CSV"

          attach_file "file_csv_file", Rails.root.join("test/fixtures/files/gobierto_plans/table_custom_fields_node_prefix.csv")
          within "form.new_file" do
            with_stubbed_s3_file_upload do
              click_button "Import from CSV file"
            end
          end

          within ".flash-message", match: :first do
            assert has_content? "Data imported successfully"
          end

          imported_directory = node.custom_field_records.find_by(custom_field: table_custom_field_directory).value

          assert_equal 2, imported_directory.count
          assert_equal "miguel@example.org", imported_directory.first["email"]
          assert_equal 999_999_999, imported_directory.first["phone_number"]

          imported_indicators = node.custom_field_records.find_by(custom_field: table_custom_field_indicators).value

          assert_equal 1, imported_indicators.count
          assert_equal 45.0, imported_indicators.first["objective"]
          assert_equal 23.0, imported_indicators.first["value_reached"]
          assert_equal "2020", imported_indicators.first["date"]
        end
      end

      def test_regular_admin_manager_import
        plan.nodes.each(&:destroy)
        allow_regular_admin_manage_plans

        with_signed_in_admin(regular_admin) do
          with_current_site(site) do
            visit path

            click_link "Import from CSV"

            attach_file "plan_csv_file", Rails.root.join("test/fixtures/files/gobierto_plans/plan.csv")
            within "form.new_plan" do
              with_stubbed_s3_file_upload do
                click_button "Import from CSV file"
              end
            end

            within ".flash-message", match: :first do
              assert has_content? "Data imported successfully"
            end
          end
        end
      end

      def test_regular_admin_editor_import
        allow_regular_admin_edit_plans
        @path = admin_plans_plan_import_csv_path(plan)

        with_signed_in_admin(regular_admin) do
          with_current_site(site) do
            visit path

            assert has_alert? "You are not authorized to perform this action"
          end
        end
      end

      def test_regular_admin_moderator_import
        allow_regular_admin_moderate_plans
        @path = admin_plans_plan_import_csv_path(plan)

        with_signed_in_admin(regular_admin) do
          with_current_site(site) do
            visit path

            assert has_alert? "You are not authorized to perform this action"
          end
        end
      end

      def test_import_with_vocabulary_already_in_use
        site.plans.create(plan.attributes.slice("title_translations", "introduction_translations", "plan_type_id", "vocabulary_id").merge(year: plan.year + 1))

        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit path

            click_link "Import from CSV"

            within "form.new_plan" do
              assert has_content? "The vocabulary configured for this plan is already configured for someone else"
              assert has_no_button? "Import from CSV file"
            end
          end
        end
      end

      def test_import_with_vocabulary_with_terms_used
        plan.update_attribute(:vocabulary_id, vocabulary_used_in_other_context.id)

        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit path

            click_link "Import from CSV"

            attach_file("plan_csv_file", "test/fixtures/files/gobierto_plans/plan.csv")
            within "form.new_plan" do
              with_stubbed_s3_file_upload do
                click_button "Import from CSV file"
              end
            end

            assert has_alert? "The vocabulary contains terms used in other parts of the application"
          end
        end
      end

      def test_import_with_default_publish_setting
        plan.nodes.each(&:destroy)
        plan.update_attribute(:publish_last_version_automatically, true)
        allow_regular_admin_manage_plans

        with_signed_in_admin(regular_admin) do
          with_current_site(site) do
            visit path
            click_link "Import from CSV"

            attach_file "plan_csv_file", Rails.root.join("test/fixtures/files/gobierto_plans/plan.csv")
            within "form.new_plan" do
              with_stubbed_s3_file_upload do
                click_button "Import from CSV file"
              end
            end

            within ".flash-message", match: :first do
              assert has_content? "Data imported successfully"
            end

            node = plan.nodes.find_by(external_id: "ext_01")
            assert node.published?
            assert_equal 1, node.published_version

            attach_file "plan_csv_file", Rails.root.join("test/fixtures/files/gobierto_plans/plan.csv")
            within "form.new_plan" do
              with_stubbed_s3_file_upload do
                click_button "Import from CSV file"
              end
            end

            within ".flash-message", match: :first do
              assert has_content? "Data imported successfully"
            end

            node.reload
            assert node.published?
            assert_equal 1, node.published_version

            attach_file "plan_csv_file", Rails.root.join("test/fixtures/files/gobierto_plans/plan_updated.csv")
            within "form.new_plan" do
              with_stubbed_s3_file_upload do
                click_button "Import from CSV file"
              end
            end

            within ".flash-message", match: :first do
              assert has_content? "Data imported successfully"
            end

            node.reload
            assert node.published?
            assert_equal 2, node.published_version
          end
        end
      end

    end
  end
end
