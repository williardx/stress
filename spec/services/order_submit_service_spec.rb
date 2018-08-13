require 'rails_helper'
require 'webmock/rspec'
require 'support/gravity_helper'

describe OrderSubmitService, type: :services do
  let(:partner_id) { 'partner-1' }
  let(:credit_card_id) { 'cc-1' }
  let(:order) { Fabricate(:order, partner_id: partner_id, credit_card_id: credit_card_id, fulfillment_type: Order::PICKUP, external_credit_card_id: 'card-1', external_customer_id: 'cust-1') }
  let!(:line_items) { [Fabricate(:line_item, order: order, price_cents: 2000_00), Fabricate(:line_item, order: order, price_cents: 8000_00)] }
  let(:merchant_account_id) { 'ma-1' }
  let(:charge_success) { { id: 'ch-1' } }
  let(:charge_failure) { { failure_message: 'some_error' } }
  let(:partner_merchant_accounts) { [{ external_id: 'ma-1' }, { external_id: 'some_account' }] }
  let(:authorize_charge_params) do
    {
      source_id: order.external_credit_card_id,
      destination_id: merchant_account_id,
      customer_id: order.external_customer_id,
      amount: order.buyer_total_cents,
      currency_code: order.currency_code
    }
  end

  describe '#submit!' do
    context 'with a partner with a merchant account' do
      context 'with a successful transaction' do
        before(:each) do
          ActiveJob::Base.queue_adapter = :test
          allow(GravityService).to receive(:get_merchant_account).with(partner_id).and_return(partner_merchant_accounts.first)
          allow(PaymentService).to receive(:authorize_charge).with(authorize_charge_params).and_return(charge_success)
          allow(TransactionService).to receive(:create_success!).with(order, charge_success)
          allow(Adapters::GravityV1).to receive(:request).with("/partner/#{partner_id}/all").and_return(gravity_v1_partner)
          OrderSubmitService.submit!(order)
        end
        it 'authorizes a charge for the full amount of the order' do
          expect(PaymentService).to have_received(:authorize_charge).with(authorize_charge_params)
        end

        it 'creates a record of the transaction' do
          expect(TransactionService).to have_received(:create_success!).with(order, charge_success)
        end

        it 'updates the order expiration time' do
          expect(order.state_expires_at).to eq(order.state_updated_at + 2.days)
        end

        it 'updates the order state to SUBMITTED' do
          expect(order.state).to eq Order::SUBMITTED
          expect(order.state_updated_at).not_to be_nil
        end

        it 'updates external_charge_id with the id of the charge' do
          expect(order.external_charge_id).to eq(charge_success[:id])
        end

        it 'queues a job for posting event' do
          expect(PostNotificationJob).to have_been_enqueued
        end

        it 'sets commission_fee_cents' do
          expect(order.commission_fee_cents).to eq 8000_00
        end

        it 'sets transaction_fee_cents' do
          expect(order.transaction_fee_cents).to eq 290_30
        end
      end

      context 'with an unsuccessful transaction' do
        it 'creates a record of the transaction' do
          allow(GravityService).to receive(:get_merchant_account).with(partner_id).and_return(partner_merchant_accounts.first)
          allow(PaymentService).to receive(:authorize_charge).with(authorize_charge_params).and_raise(Errors::PaymentError.new('some_error', charge_failure))
          allow(TransactionService).to receive(:create_failure!).with(order, charge_failure)
          expect { OrderSubmitService.submit!(order) }.to raise_error(Errors::PaymentError)
          expect(TransactionService).to have_received(:create_failure!).with(order, charge_failure)
        end
      end
    end
  end

  describe '#calculate_commission' do
    context 'with successful gravity call' do
      before do
        stub_request(:get, %r{partner\/#{partner_id}/all}).to_return(status: 200, body: gravity_v1_partner.to_json)
      end
      it 'returns calculated commission fee' do
        expect(OrderSubmitService.calculate_commission(order)).to eq 8000_00.0
      end
    end
    context 'with failed gravity call' do
      before do
        stub_request(:get, %r{partner\/#{partner_id}}).to_return(status: 404, body: { error: 'not found' }.to_json)
      end
      it 'raises OrderError' do
        expect do
          OrderSubmitService.calculate_commission(order)
        end.to raise_error(Errors::OrderError, /Cannot fetch partner/)
      end
    end
  end

  describe '#calculate_transaction' do
    it 'returns proper transaction fee' do
      expect(OrderSubmitService.calculate_transaction_fee(order)).to eq 290_30
    end
  end
end
