class WebauthnVerificationsController < ApplicationController
  before_action :set_user

  def prompt
    redirect_to root_path, alert: t(".no_webauthn_devices") if @user.webauthn_credentials.blank?

    @webauthn_options = @user.webauthn_options_for_get

    session[:webauthn_authentication] = {
      "challenge" => @webauthn_options.challenge,
      "user" => @user.id
    }
  end

  def authenticate
    # TODO: check if path token is expired
    webauthn_credential.verify(
      challenge,
      public_key: user_webauthn_credential.public_key,
      sign_count: user_webauthn_credential.sign_count
    )

    user_webauthn_credential.update!(sign_count: webauthn_credential.sign_count)
    # TODO: generate webauthn verification otp

    # TODO: render html with webauthn verification otp instead of json
    render json: { message: "success" }
  rescue WebAuthn::Error => e
    render json: { message: e.message }, status: :unauthorized
  rescue ActionController::ParameterMissing
    render json: { message: "Credentials required" }, status: :unauthorized
  ensure
    session.delete(:webauthn_authentication)
  end

  private

  def set_user
    verification = WebauthnVerification.find_by(path_token: webauthn_token_param)
    if !verification || verification.path_token_expires_at < Time.now.utc
      render_not_found
    else
      @user = verification.user
    end
  end

  def webauthn_credential
    @webauthn_credential ||= WebAuthn::Credential.from_get(credential_params)
  end

  def user_webauthn_credential
    @user_webauthn_credential ||= @user.webauthn_credentials.find_by(
      external_id: webauthn_credential.id
    )
  end

  def challenge
    session.dig(:webauthn_authentication, "challenge")
  end

  def credential_params
    @credential_params ||= params.require(:credentials).permit(
      :id,
      :type,
      :rawId,
      response: %i[authenticatorData attestationObject clientDataJSON signature]
    )
  end

  def webauthn_token_param
    params.permit(:webauthn_token).require(:webauthn_token)
  end
end
