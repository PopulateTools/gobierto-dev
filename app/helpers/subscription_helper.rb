# frozen_string_literal: true

module SubscriptionHelper
  def subscription_message(object, action)
    class_name = object.class.name
    item = class_name.demodulize.downcase

    if action == "followed"
      t(".#{item}_followed")
    elsif action == "follow"
      t(".follow_#{item}")
    end
  end
end
