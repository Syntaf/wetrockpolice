class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  after_create :send_admin_mail
  serialize :manages, Array

  def active_for_authentication?
    super && approved?
  end

  def inactive_message
    approved ? super : :not_approved
  end

  def send_reset_password_instructions(attributes={})
    recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)

    if !recoverable.approved?
      recoverable.errors[:base] << I18n.t("devise.failure_not_approved")
    elsif recoverable.persisted?
      recoverable.send_reset_password_instructions
    end

    recoverable
  end

  def send_admin_mail
    AdminMailer.new_user_waiting_for_approval(email).deliver
  end
end
