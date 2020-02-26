# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/membership_mailer
class MembershipMailerPreview < ActionMailer::Preview
  def new_membership_email
    MembershipMailer.with(application: JointMembershipApplication.where(paid_cash: false).first)
                    .signup_confirmation
  end
end
