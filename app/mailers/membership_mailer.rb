# frozen_string_literal: true

class MembershipMailer < ApplicationMailer
  include Roadie::Rails::Automatic

  default from: 'Southern Nevada Climbers Coalition <admin@wetrockpolice.com>'

  def signup_confirmation
    @application = params[:application]
    mail(to: @application.email, subject: 'Access Fund Membership')
  end
end
