# frozen_string_literal: true

module GobiertoAdmin
  module GobiertoPlans
    class PlansController < GobiertoAdmin::GobiertoPlans::BaseController
      class HasDependentResources < StandardError; end

      before_action -> { module_allowed_action!(current_admin, current_admin_module, :manage) }, except: [:index, :plan]

      def index
        @plans = current_site.plans.sort_by_updated_at
        @archived_plans = current_site.plans.only_archived.sort_by_updated_at
      end

      def new
        @plan_form = PlanForm.new(site_id: current_site.id)
        @plan_visibility_levels = plan_visibility_levels
        @plan_types = find_plan_types
        @vocabularies = current_site.vocabularies
      end

      def edit
        @plan = find_plan
        @preview_item_url = gobierto_plans_plan_type_preview_url(@plan, host: current_site.domain)
        @plan_types = find_plan_types
        @plan_visibility_levels = plan_visibility_levels
        @vocabularies = current_site.vocabularies

        @plan_form = PlanForm.new(
          @plan.attributes.except(*ignored_plan_attributes).merge(site_id: current_site.id)
        )
      end

      def create
        @plan_form = PlanForm.new(plan_params.merge(site_id: current_site.id))

        if @plan_form.save
          track_create_activity

          redirect_to(
            edit_admin_plans_plan_path(@plan_form.plan),
            notice: t(".success_html", link: gobierto_plans_plan_type_preview_url(@plan_form.plan, host: current_site.domain))
          )
        else
          @plan_types = find_plan_types
          @plan_visibility_levels = plan_visibility_levels
          @vocabularies = current_site.vocabularies

          render :new
        end
      end

      def update
        @plan = find_plan

        @plan_form = PlanForm.new(
          plan_params.merge(id: params[:id], site_id: current_site.id)
        )

        if @plan_form.save
          track_update_activity

          redirect_to(
            edit_admin_plans_plan_path(@plan),
            notice: t(".success_html", link: gobierto_plans_plan_type_preview_url(@plan_form.plan, host: current_site.domain))
          )
        else
          @plan_types = find_plan_types
          @plan_visibility_levels = plan_visibility_levels
          @vocabularies = current_site.vocabularies

          render :edit
        end
      end

      def destroy
        @plan = find_plan

        @plan.destroy

        redirect_to admin_plans_plans_path, notice: t(".success")
      end

      def delete_contents
        @plan = find_plan

        ActiveRecord::Base.transaction do
          @plan.nodes.destroy_all
          destroy_terms(@plan.categories_vocabulary)
          destroy_terms(@plan.statuses_vocabulary)
          @custom_fields_form = ::GobiertoAdmin::GobiertoCommon::CustomFieldRecordsForm.new(
            site_id: current_site.id,
            item: @plan.nodes.new,
            instance: @plan
          )
          @custom_fields_form.associated_vocabularies.each do |vocabulary|
            destroy_terms(vocabulary)
          end
        end

        # Update plan cache
        @plan.touch

        redirect_to(
          edit_admin_plans_plan_path(@plan),
          notice: t(".success")
        )
      rescue HasDependentResources => e
        redirect_to(
          edit_admin_plans_plan_path(@plan),
          alert: e.message
        )
      end

      def recover
        @plan = find_archived_plan
        @plan.restore

        redirect_to admin_plans_plans_path, notice: t(".success")
      end

      def import_csv
        @plan = ::GobiertoPlans::PlanDecorator.new(find_plan)
        @plan_data_form = PlanDataForm.new(plan: @plan)
        @plan_table_custom_fields_form = PlanTableCustomFieldsForm.new(plan: @plan)
      end

      def export_csv
        @plan = find_plan
        respond_to do |format|
          format.csv { render csv: ::GobiertoPlans::PlanDataDecorator.new(@plan).csv, filename: @plan.title.parameterize.dasherize }
        end
      end

      def export_indicator_csv
        @plan = find_plan
        respond_to do |format|
          format.csv { render csv: ::GobiertoPlans::IndicatorDataDecorator.new(@plan).csv, filename: "#{@plan.title.parameterize.dasherize}-indicators" }
        end
      end

      def import_data
        @plan = find_plan

        if @plan.vocabulary_shared_with_other_plans?
          redirect_to(
            admin_plans_plan_import_csv_path(@plan),
            alert: t("gobierto_admin.module_helper.not_enabled")
          )
          return
        end

        if params[:plan].blank?
          redirect_to(
            admin_plans_plan_import_csv_path(@plan),
            alert: t(".missing_file")
          ) and return
        end

        @plan_data_form = PlanDataForm.new(import_csv_params.merge(plan: @plan))
        @plan_table_custom_fields_form = PlanTableCustomFieldsForm.new(plan: @plan)
        if @plan_data_form.save
          track_import_csv_data_activity
          redirect_to(
            admin_plans_plan_import_csv_path(@plan),
            notice: t(".success_html", link: gobierto_plans_plan_type_preview_url(@plan, host: current_site.domain))
          )
        else
          render :import_csv
        end
      end

      def import_table_custom_fields
        @plan = find_plan

        if params[:file].blank?
          redirect_to(
            admin_plans_plan_import_csv_path(@plan),
            alert: t("gobierto_admin.gobierto_plans.plans.import_data.missing_file")
          ) and return
        end

        @plan_data_form = PlanDataForm.new(plan: @plan)
        @plan_table_custom_fields_form = PlanTableCustomFieldsForm.new(import_csv_params(:file).merge(plan: @plan))
        if @plan_table_custom_fields_form.save
          track_import_csv_data_activity
          redirect_to(
            admin_plans_plan_import_csv_path(@plan),
            notice: t("gobierto_admin.gobierto_plans.plans.import_data.success_html", link: gobierto_plans_plan_type_preview_url(@plan, host: current_site.domain))
          )
        else
          render :import_csv
        end
      end

      private

      def track_create_activity
        Publishers::GobiertoPlansPlanActivity.broadcast_event("plan_created", default_activity_params.merge(subject: @plan_form.plan))
      end

      def destroy_terms(vocabulary)
        vocabulary.terms.each do |term|
          next if term.destroy

          raise HasDependentResources, t(
            "gobierto_admin.gobierto_plans.plans.delete_contents.term_deletion_failed_html",
            vocabulary: term.vocabulary.name,
            term: term.name,
            message: term.errors.full_messages.to_sentence
          )
        end
      end

      def track_update_activity
        Publishers::GobiertoPlansPlanActivity.broadcast_event("plan_updated", default_activity_params.merge(subject: @plan))
      end

      def track_import_csv_data_activity
        Publishers::GobiertoPlansPlanActivity.broadcast_event("plan_data_csv_imported", default_activity_params.merge(subject: @plan))
      end

      def default_activity_params
        { ip: remote_ip, author: current_admin, site_id: current_site.id }
      end

      def plan_params
        params.require(:plan).permit(
          :slug,
          :plan_type_id,
          :year,
          :configuration_data,
          :visibility_level,
          :css,
          :vocabulary_id,
          :statuses_vocabulary_id,
          :publish_last_version_automatically,
          title_translations: [*I18n.available_locales],
          footer_translations: [*I18n.available_locales],
          introduction_translations: [*I18n.available_locales]
        )
      end

      def import_csv_params(key = :plan)
        params.require(key).permit(:csv_file)
      end

      def ignored_plan_attributes
        %w(created_at updated_at site_id archived_at vocabulary_id statuses_vocabulary_id)
      end

      def find_plan_by_slug
        current_site.plans.find_by(slug: params[:plan_id] || params[:id])
      end

      def find_plan
        current_site.plans.find(params[:id] || params[:plan_id])
      end

      def find_archived_plan
        current_site.plans.with_archived.find(params[:plan_id] || params[:id])
      end

      def plan_visibility_levels
        ::GobiertoPlans::Plan.visibility_levels
      end

      def find_plan_types
        current_site.plan_types.all.collect { |plan_type| [plan_type.name, plan_type.id] }
      end

      def tree(relation, level = 0)
        level_relation = relation.where(level: level).order(position: :asc)
        return [] if level_relation.blank?

        level_relation.where(level: level).map do |node|
          [node, tree(node.terms, level + 1)]
        end.to_h
      end
    end
  end
end
