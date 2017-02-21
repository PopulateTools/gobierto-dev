require "test_helper"

module GobiertoAdmin
  module GobiertoBudgetConsultations
    class ConsultationResponseFormTest < ActiveSupport::TestCase
      def valid_consultation_response_form
        @valid_consultation_response_form ||= ConsultationResponseForm.new(
          user_id: user.id,
          consultation_id: consultation.id,
          selected_options: Hash[consultation_items.map do |item|
            [item.id.to_s, nil]
          end]
        )
      end

      def invalid_consultation_response_form
        @invalid_consultation_response_form ||= ConsultationResponseForm.new(
          user_id: nil,
          consultation_id: nil,
          selected_options: {}
        )
      end

      def consultation
        @consultation ||= gobierto_budget_consultations_consultations(:madrid_open)
      end

      def admin
        @admin ||= gobierto_admin_admins(:tony)
      end

      def site
        @site ||= sites(:madrid)
      end

      def user
        @user ||= users(:peter)
      end

      def consultation_items
        @consultation_items ||= consultation.consultation_items
      end

      def test_valid_with_valid_attributes
        assert valid_consultation_response_form.save
      end

      def test_error_messages_with_invalid_attributes
        refute invalid_consultation_response_form.save

        assert_equal 1, invalid_consultation_response_form.errors.messages[:user].size
        assert_equal 1, invalid_consultation_response_form.errors.messages[:consultation].size
        assert_equal 1, invalid_consultation_response_form.errors.messages[:site].size
        assert_equal 1, invalid_consultation_response_form.errors.messages[:selected_options].size
      end
    end
  end
end
