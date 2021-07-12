# frozen_string_literal: true

require "test_helper"

module GobiertoBudgetConsultations
  class ConsultationPreviewTest < ActionDispatch::IntegrationTest
    def setup
      super
      @path = admin_budget_consultations_path
    end

    def admin
      @admin ||= gobierto_admin_admins(:nick)
    end

    def site
      @site ||= sites(:madrid)
    end

    def active_consultation
      @active_consultation ||= gobierto_budget_consultations_consultations(:madrid_open)
    end

    def draft_consultation
      @draft_consultation ||= gobierto_budget_consultations_consultations(:madrid_draft)
    end

    def test_preview_active_consultation
      with_signed_in_admin(admin) do
        with_current_site(site) do
          visit @path

          within "tr#consultation-item-#{active_consultation.id}" do
            preview_link = find("a", text: "View consultation")

            refute preview_link[:href].include?(admin.preview_token)

            preview_link.click
          end

          assert_equal gobierto_budget_consultations_consultation_path(active_consultation), current_path

          # comment because module budgets consultations will be deleted
          # within "div.consultation-intro-wrapper" do
          #   assert has_content?(active_consultation.description)
          # end
        end
      end
    end

    def test_preview_draft_consultation_as_admin
      with_signed_in_admin(admin) do
        with_current_site(site) do
          visit @path

          within "tr#consultation-item-#{draft_consultation.id}" do
            preview_link = find("a", text: "View consultation")

            assert preview_link[:href].include?(admin.preview_token)

            preview_link.click
          end

          assert_equal gobierto_budget_consultations_consultation_path(draft_consultation), current_path

          # comment because module budgets consultations will be deleted
          # within "div.consultation-intro-wrapper" do
          #   assert has_content?(draft_consultation.description)
          # end
        end
      end
    end

    def test_preview_draft_page_if_not_admin
      with_current_site(site) do
        visit gobierto_budget_consultations_consultation_path(draft_consultation)
        assert_equal 404, page.status_code
      end
    end
  end
end
