# frozen_string_literal: true

class MembershipMailer < ApplicationMailer
  default from: 'admin@wetrockpolice.com'

  def payment_complete
    @application = params[:application]
    mail(to: @application.email, subject: 'Access Fund Membership')
  end
end
