# frozen_string_literal: true

class MigratePollAnswerDemographicInfo < ActiveRecord::Migration[5.2]

  def poll_answer_class
    ::GobiertoParticipation::PollAnswer
  end

  def up
    if defined? GobiertoParticipation::PollAnswer
      poll_answer_class.reset_column_information

      User.all.each do |user|
        poll_answer_class.by_user(user).each do |answer|
          answer.update_attribute(
            :encrypted_meta,
            SecretAttribute.encrypt(poll_answer_meta(user, answer))
          )
        end
      end
    end
  end

  def down
    if defined? GobiertoParticipation::PollAnswer
      poll_answer_class.update_all(encrypted_meta: nil)
    end
  end

  private

  def poll_answer_meta(user, poll_answer)
    custom_records_meta = Hash[user.custom_records.map(&:payload).map do |payload|
      [payload.keys.first, payload.values.first]
    end].symbolize_keys

    {
      gender: User.genders[user.gender],
      birthdate: user.date_of_birth.iso8601,
      age: age_on_date(user, poll_answer)
    }.merge(custom_records_meta)
  end

  def age_on_date(user, poll_answer)
    dob = user.date_of_birth
    answer_date = poll_answer.created_at
    answer_date.year - dob.year - ((answer_date.month > dob.month || (answer_date.month == dob.month && answer_date.day >= dob.day)) ? 0 : 1)
  end

end
