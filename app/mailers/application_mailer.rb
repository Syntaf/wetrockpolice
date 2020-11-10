# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'admin@wetrockpolice.com'
  layout 'mailer'
end
