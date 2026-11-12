# frozen_string_literal: true

# A partner site's bearer key for the rain data API (Api::V1). Keys are
# created with `bin/rails "api_keys:create[Site name]"`, which prints the key
# once; only its SHA-256 digest is stored. Keys are random and high-entropy,
# so a plain digest (no bcrypt) is enough and allows an indexed lookup.
# Revoke a key by unticking `active` in Rails Admin.
class ApiKey < ApplicationRecord
  PREFIX = 'wrp_'
  # last_used_at is a "who still uses this" signal, not an audit log, so it
  # isn't rewritten on every request.
  USAGE_RESOLUTION = 1.hour

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true

  # Returns [api_key, token]. The token is not recoverable afterwards.
  def self.generate!(name:)
    token = "#{PREFIX}#{SecureRandom.base58(32)}"
    [create!(name: name, token_digest: digest(token)), token]
  end

  def self.authenticate(token)
    return if token.blank?

    find_by(token_digest: digest(token), active: true)
  end

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token)
  end

  def record_use!(now: Time.current)
    return if last_used_at && last_used_at > now - USAGE_RESOLUTION

    update!(last_used_at: now)
  end
end
