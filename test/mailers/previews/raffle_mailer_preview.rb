# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/raffle_mailer
class RaffleMailerPreview < ActionMailer::Preview
  def new_raffle_entry_email
    RaffleMailer.with(
      raffle_entry: RaffleEntry.first
    ).entered
  end
end
