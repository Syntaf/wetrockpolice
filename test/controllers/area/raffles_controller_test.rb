# frozen_string_literal: true

require 'test_helper'
require 'json'

class RafflesControllerTest < ActionDispatch::IntegrationTest
  include RaffleEntrySubmission
end