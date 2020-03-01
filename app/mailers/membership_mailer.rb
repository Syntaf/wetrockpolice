# frozen_string_literal: true

class MembershipMailer < ApplicationMailer
  default from: 'Southern Nevada Climbers Coalition <admin@wetrockpolice.com>'

  def confirmation
    @membership = params[:membership]
    mail(to: @membership.email, subject: 'Access Fund Membership')
  end
end
