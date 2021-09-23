# frozen_string_literal: true

require 'mail'

module EmailValidatable
  extend ActiveSupport::Concern

  class EmailValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      return if value.match?(Devise.email_regexp) || value.nil?

      record.errors.add attribute, (options[:message] || 'is not an email')
    end
  end
end
