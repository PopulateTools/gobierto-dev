# frozen_string_literal: true

require "test_helper"
require_relative "base_index"

module GobiertoPeople
  module People
    class PersonMessageTest < ActionDispatch::IntegrationTest
      include BaseIndex

      def setup
        super
        @path = gobierto_people_person_path(person.slug)
      end

      def site
        @site ||= sites(:madrid)
      end

      def person
        @person ||= gobierto_people_people(:richard)
      end

      def user
        @user ||= users(:dennis)
      end

      def test_send_message_as_anonymous_user
        with_current_site(site) do
          visit @path

          click_link "Send an email"
          fill_in "gobierto_people_person_message_name", with: "Sender"
          fill_in "gobierto_people_person_message_email", with: "foo@example.com"
          fill_in "gobierto_people_person_message_body", with: "This is my message"
          click_button "Send"

          assert has_message?("Message sent successfully")

          refute ActionMailer::Base.deliveries.empty?
          email = ActionMailer::Base.deliveries.last

          assert_equal ["no-reply@gobierto.dev"], email.from
          assert_equal ["foo@example.com"], email.reply_to
          assert_equal [person.email], email.to
          assert_equal "You have received a new message from Transparencia y Participación", email.subject
        end
      end

      def test_send_message_as_anonymous_spam_user
        with_current_site(site) do
          visit @path

          click_link "Send an email"

          fill_in :gobierto_people_person_message_name, with: "Sender"
          fill_in :gobierto_people_person_message_email, with: "spam@example.com"
          fill_in :gobierto_people_person_message_ic_email, with: "spam@example.com"
          fill_in :gobierto_people_person_message_body, with: "This is my message"

          click_button "Send"

          assert ActionMailer::Base.deliveries.empty?
        end
      end

      def test_send_message_as_logged_user
        with_signed_in_user(user) do
          visit @path

          click_link "Send an email"
          fill_in "gobierto_people_person_message_body", with: "This is my message"
          click_button "Send"

          assert has_message?("Message sent successfully")

          refute ActionMailer::Base.deliveries.empty?
          email = ActionMailer::Base.deliveries.last

          assert_equal ["no-reply@gobierto.dev"], email.from
          assert_equal [user.email], email.reply_to
          assert_equal [user.email], email.reply_to
          assert_equal [person.email], email.to
          assert_equal "You have received a new message from Transparencia y Participación", email.subject
        end
      end
    end
  end
end
