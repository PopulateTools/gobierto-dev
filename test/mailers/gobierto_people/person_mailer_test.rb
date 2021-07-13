# frozen_string_literal: true

require "test_helper"

module GobiertoPeople
  class PersonMailerTest < ActionMailer::TestCase
    def user
      @user ||= users(:reed)
    end

    def site
      @site ||= sites(:madrid)
    end

    def person
      @person ||= gobierto_people_people(:richard)
    end

    def test_new_message
      email = PersonMailer.new_message(person_id: person.id,
                                       reply_to: "foo@example.com",
                                       name: "Sender",
                                       body: "This is my message").deliver_now

      refute ActionMailer::Base.deliveries.empty?

      assert_equal ["no-reply@gobierto.dev"], email.from
      assert_equal ["foo@example.com"], email.reply_to
      assert_equal [person.email], email.to
      assert_equal "You have received a new message from Transparencia y Participación", email.subject
    end
  end
end
