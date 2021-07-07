# frozen_string_literal: true

require "digest/sha1"

class SecretAttribute

  def self.hmac(message, force_string = true)
    OpenSSL::HMAC.hexdigest("SHA256", salt, force_string ? message.to_s : message)
  end

  def self.digest(value)
    Digest::SHA1.hexdigest("#{value} + #{salt}")
  end

  def self.salt
    Rails.application.secrets.secret_key_base
  end
  private_class_method :salt

  def self.encrypt(plain_text)
    crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0..31])
    crypt.encrypt_and_sign(plain_text)
  end

  def self.decrypt(encrypted_text)
    crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0..31])
    crypt.decrypt_and_verify(encrypted_text)
  end

end
