# frozen_string_literal: true

class RaffleMailer < ApplicationMailer
  default from: 'Southern Nevada Climbers Coalition <admin@wetrockpolice.com>'

  def entered
    @raffle_entry = params[:raffle_entry]
    mail(to: @raffle_entry.email, subject: 'Wagbag Raffle Entry')
  end
end
