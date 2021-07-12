# frozen_string_literal: true

class CalculatePollAnswerUserIdHmac < ActiveRecord::Migration[5.2]

  def up
    if defined? GobiertoParticipation::PollAnswer
      ::GobiertoParticipation::PollAnswer.all.each do |poll_answer|
        poll_answer.update_attribute(
          :user_id_hmac,
          SecretAttribute.hmac(poll_answer.user_id)
        )
      end
    end
  end

  def down
    if defined? GobiertoParticipation::PollAnswer
      ::GobiertoParticipation::PollAnswer.update_all(:user_id_hmac, nil)
    end
  end

end
