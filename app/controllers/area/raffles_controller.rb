# frozen_string_literal: true

module Area
  class RafflesController < BaseController
    before_action :verify_order_id, only: %i[create]
    before_action :set_watched_area, only: %i[new]
    before_action :set_meta, only: %i[new]

    def new
      @raffle_entry = RaffleEntry.new
    end

    def create
      @raffle_entry = RaffleEntry.new(raffle_entry_params)
      @raffle_entry.save!(context: :create)

      RaffleMailer.with(raffle_entry: @raffle_entry).entered.deliver_later

      respond_json(
        status: :created,
        modal: render_to_string(
          partial: entered_partial
        )
      )
    rescue ActiveRecord::RecordInvalid
      respond_json(
        status: :bad_request,
        errors: @raffle_entry.errors
      )
    end

    def validate
      raffle_entry = RaffleEntry.new(raffle_entry_params)
      raffle_entry.prevalidate = true

      unless raffle_entry.valid?
        respond_json(
          status: :bad_request,
          errors: raffle_entry.errors
        ) and return
      end

      respond_json(status: :ok)
    end

    private

    def respond_json(content)
      status = content[:status]

      render(
        json: content,
        status: status
      )
    end

    def entered_partial
      'raffle_entry_confirmation_modal.html.erb'
    end

    def verify_order_id
      order_id = params[:raffle_entry][:order_id]

      return if PayPalPayments::OrderValidator.call(order_id)

      respond_json(
        status: :payment_required,
        message: 'Invalid order ID Supplied'
      )
    end

    def raffle_entry_params
      params.require(:raffle_entry).permit(
        :contact,
        :email,
        :phone_number,
        :order_id,
        :amount_paid
      )
    end

    def set_meta
      @page_title = 'Wagbag Raffle'
      @page_description = <<~TEXT
        Take part in SNCC's raffle to win big and support the local community
        efforts around waste disposal!
      TEXT
    end
  end
end
