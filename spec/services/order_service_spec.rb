require 'rails_helper'
require 'webmock/rspec'
require 'support/gravity_helper'

describe OrderService, type: :services do
  let(:credit_card_id) { 'abc123' }
  let(:credit_card) { { external_id: 'card-1', customer_account: { external_id: 'cust-1' } } }
  let(:invalid_credit_card) { { external_id: 'card-1' } }
  let(:order) { Fabricate(:order) }
  describe '#set_payment!' do
    it 'fetches a credit card given the credit card ID' do
      expect(GravityService).to receive(:get_credit_card).with(credit_card_id).and_return(credit_card)
      OrderService.set_payment!(order, credit_card_id: credit_card_id)
    end
    context 'with a valid credit card' do
      it 'updates the order' do
        allow(GravityService).to receive(:get_credit_card).with(credit_card_id).and_return(credit_card)
        OrderService.set_payment!(order, credit_card_id: credit_card_id)
        expect(order.credit_card_id).to eq credit_card_id
        expect(order.external_credit_card_id).to eq credit_card[:external_id]
        expect(order.external_customer_id).to eq credit_card[:customer_account][:external_id]
      end
    end
    context 'with an invalid credit card' do
      it 'raises an OrderError' do
        allow(GravityService).to receive(:get_credit_card).with(credit_card_id).and_return(invalid_credit_card)
        expect { OrderService.set_payment!(order, credit_card_id: credit_card_id) }.to raise_error(Errors::OrderError)
      end
    end
  end

  describe '#validate_credit_card!' do
    it 'raises an error if the credit card does not have an external id' do
      expect { OrderService.validate_credit_card!(customer_account: { external_id: 'cust-1' }, deactivated_at: nil) }.to raise_error(Errors::OrderError)
    end
    it 'raises an error if the credit card does not have a customer id' do
      expect { OrderService.validate_credit_card!(external_id: 'cc-1') }.to raise_error(Errors::OrderError)
      expect { OrderService.validate_credit_card!(external_id: 'cc-1', customer_account: { some_prop: 'some_val' }, deactivated_at: nil) }.to raise_error(Errors::OrderError)
    end
    it 'raises an error if the card is deactivated' do
      expect { OrderService.validate_credit_card!(external_id: 'cc-1', customer_account: { external_id: 'cust-1' }, deactivated_at: 'today') }.to raise_error(Errors::OrderError)
    end
  end
end
