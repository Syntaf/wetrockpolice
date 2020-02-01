module PaymentServices
    class PaypalClient
        def new
            @environment = if Rails.env.development
                PayPal::SandboxEnvironment.new(ENV['PAYPAL_CLIENT_ID'], ENV['PAYPAL_CLIENT_SECRET']);
            else
                PayPal::ProductionEnvironment.new(ENV['PAYPAL_CLIENT_ID'], ENV['PAYPAL_CLIENT_SECRET']);
            end

            @client = PayPal::PayPalHttpClient.new(@environment)
        end

        def client
            @client
        end
    end
end