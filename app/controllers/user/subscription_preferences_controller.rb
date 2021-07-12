class User::SubscriptionPreferencesController < User::BaseController
  before_action :authenticate_user!

  def update
    @user_subscription_preferences_form = User::SubscriptionPreferencesForm.new(
      user_subscription_params.merge(
        user: current_user,
        site: current_site
      )
    )

    if @user_subscription_preferences_form.save
      flash[:notice] = t(".update_success")
    else
      flash[:alert] = t(".error", details: @user_subscription_preferences_form.errors.full_messages.to_sentence)
    end

    redirect_to user_subscriptions_path
  end

  private

  def user_subscription_params
    params.require(:user_subscription_preferences).permit(
      :notification_frequency,
      :site_to_subscribe,
      modules: [],
      gobierto_people_people: [],
      gobierto_budget_consultations_consultations: [],
    )
  end
end
