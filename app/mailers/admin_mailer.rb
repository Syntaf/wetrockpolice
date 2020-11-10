# frozen_string_literal: true

class AdminMailer < Devise::Mailer
  default from: 'admin@wetrockpolice.com'
  layout 'mailer'

  def new_user_waiting_for_approval(email)
    @email = email

    mail(
      to: 'gmercer015@gmail.com',
      subject: 'New User Awaiting Admin Approval'
    )
  end
end
