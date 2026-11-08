# frozen_string_literal: true

require 'test_helper'

class ApiKeyTest < ActiveSupport::TestCase
  test 'generate! returns a usable token and stores only its digest' do
    api_key, token = ApiKey.generate!(name: 'Mountain Project')

    assert token.start_with?('wrp_')
    assert_operator token.length, :>=, 36
    assert_not_includes api_key.token_digest, token
    assert_equal api_key, ApiKey.authenticate(token)
  end

  test 'unknown, blank and revoked tokens do not authenticate' do
    assert_nil ApiKey.authenticate('wrp_not_a_real_key')
    assert_nil ApiKey.authenticate('')
    assert_nil ApiKey.authenticate('wrp_revoked_key')
    assert_equal api_keys(:partner), ApiKey.authenticate('wrp_test_partner_key')
  end

  test 'record_use! writes last_used_at at most once an hour' do
    key = api_keys(:partner)
    now = Time.utc(2026, 11, 8, 12)

    key.record_use!(now: now)
    key.record_use!(now: now + 30.minutes)
    assert_equal now, key.reload.last_used_at

    key.record_use!(now: now + 2.hours)
    assert_equal now + 2.hours, key.reload.last_used_at
  end
end
