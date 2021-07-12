# frozen_string_literal: true

class User::SessionsController < User::BaseController
  before_action :check_auth_modules, only: [:new]
  before_action :authenticate_user!, only: [:destroy]
  before_action :require_no_authentication, only: [:new, :create]
  before_action :define_referrer_url, only: [:new]

  layout "user/layouts/sessions"

  def new
    @user_session_form = User::SessionForm.new(referrer_url: @referrer_url, site: @site)
    @user_registration_form = User::RegistrationForm.new(referrer_url: @referrer_url, referrer_entity: referrer_entity)
    @user_password_form = User::NewPasswordForm.new

    if params[:open_modal]
      @modal = true
      render(:new, layout: false) && return if request.xhr?
    end
  end

  def create
    @user_session_form = User::SessionForm.new(user_session_params)

    if @user_session_form.save
      user = @user_session_form.user

      user.update_session_data(remote_ip)
      sign_in_user(user.id)

      redirect_to(
        after_sign_in_path(@user_session_form.referrer_url),
        notice: t(".success")
      )
    else
      @user_registration_form = User::RegistrationForm.new
      @user_password_form = User::NewPasswordForm.new

      flash.now[:alert] = t(".error")

      if params[:open_modal]
        render(:new, layout: false) && return if request.xhr?
      end

      render :new
    end
  end

  def destroy
    sign_out_user
    redirect_to after_sign_out_path, notice: t(".success")
  end

  private

  def user_session_params
    params.require(:user_session).permit(:email, :password, :referrer_url).merge(site: @site)
  end

  def referrer_entity
    if request.referrer.present?
      if request.referrer.include?("consultas-presupuestos")
        "GobiertoBudgetConsultations::Consultation"
      end
    end
  end

  def define_referrer_url
    @referrer_url = request.referrer
  end

  def check_auth_modules
    redirect_to auth_path(request.parameters) and return if auth_modules_present?
  end
end
