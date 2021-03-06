# frozen_string_literal: true

module BraintreeServices
  class TransactionBuilder
    attr_reader :payment_options, :transaction

    def initialize(transaction, payment_options)
      @payment_options = payment_options
      @transaction = transaction
    end

    def build
      Payment::Braintree::Transaction.create!(attributes)
    end

    private

    def status
      %(settled settling submitted_for_settlement).include?(transaction.status) ? :success : :failure
    end

    def attributes
      {
        status: status,
        amount: transaction.amount,
        currency: transaction.currency_iso_code,
        transaction_id: transaction.id,
        transaction_type: transaction.type,
        merchant_account_id: transaction.merchant_account_id,
        transaction_created_at: transaction.created_at,
        payment_instrument_type: transaction.payment_instrument_type,
        processor_response_code: transaction.processor_response_code,
        customer_id: payment_options.customer.customer_id,
        payment_method: payment_options.payment_method,
        page_id: payment_options.page.id
      }
    end
  end
end
