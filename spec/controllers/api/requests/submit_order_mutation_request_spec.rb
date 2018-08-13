require 'rails_helper'
require 'support/gravity_helper'
require 'support/use_stripe_mock'

describe Api::GraphqlController, type: :request do
  include_context 'use stripe mock'
  describe 'submit_order mutation' do
    include_context 'GraphQL Client'
    let(:partner_id) { jwt_partner_ids.first }
    let(:user_id) { jwt_user_id }
    let(:credit_card_id) { 'cc-1' }
    let(:merchant_account) { { external_id: 'ma-1' } }
    let(:order) do
      Fabricate(
        :order,
        partner_id: partner_id,
        user_id: user_id,
        credit_card_id: credit_card_id,
        external_credit_card_id: stripe_customer.default_source,
        external_customer_id: stripe_customer.id,
        shipping_address_line1: '12 Vanak St',
        shipping_address_line2: 'P 80',
        shipping_city: 'Tehran',
        shipping_postal_code: '02198',
        shipping_country: 'IR',
        fulfillment_type: Order::SHIP
      )
    end
    let(:line_item) do
      Fabricate(:line_item, order: order, price_cents: 1000_00)
    end

    let(:mutation) do
      <<-GRAPHQL
        mutation($input: SubmitOrderInput!) {
          submitOrder(input: $input) {
            order {
              id
              userId
              partnerId
              state
              commissionFeeCents
            }
            errors
          }
        }
      GRAPHQL
    end

    let(:submit_order_input) do
      {
        input: {
          id: order.id.to_s
        }
      }
    end

    before do
      order.line_items << line_item
    end

    context 'with user without permission to this order' do
      let(:user_id) { 'random-user-id-on-another-order' }
      it 'returns permission error' do
        response = client.execute(mutation, submit_order_input)
        expect(response.data.submit_order.errors).to include 'Not permitted'
        expect(order.reload.state).to eq Order::PENDING
      end
    end

    context 'with proper permission' do
      context 'with order without shipping info' do
        before do
          order.update_attributes! shipping_country: nil
        end
        it 'returns error' do
          response = client.execute(mutation, submit_order_input)
          expect(response.data.submit_order.errors).to include "Missing info for submitting order(#{order.id})"
          expect(order.reload.state).to eq Order::PENDING
        end
      end
      context 'with order without credit card id' do
        let(:credit_card_id) { nil }
        it 'returns error' do
          response = client.execute(mutation, submit_order_input)
          expect(response.data.submit_order.errors).to include "Missing info for submitting order(#{order.id})"
          expect(order.reload.state).to eq Order::PENDING
        end
      end
      context 'with order in non-pending state' do
        before do
          order.update_attributes! state: Order::APPROVED
        end
        it 'returns error' do
          allow(GravityService).to receive(:get_merchant_account).and_return(merchant_account)
          response = client.execute(mutation, submit_order_input)
          expect(response.data.submit_order.errors).to include 'Invalid action on this approved order'
          expect(order.reload.state).to eq Order::APPROVED
        end
      end

      it 'submits the order' do
        expect(GravityService).to receive(:get_merchant_account).and_return(merchant_account)
        expect(Adapters::GravityV1).to receive(:request).with("/partner/#{partner_id}/all").and_return(gravity_v1_partner)
        response = client.execute(mutation, submit_order_input)
        expect(response.data.submit_order.order.id).to eq order.id.to_s
        expect(response.data.submit_order.order.state).to eq 'SUBMITTED'
        expect(response.data.submit_order.order.commission_fee_cents).to eq 800_00
        expect(response.data.submit_order.errors).to match []
        expect(order.reload.state).to eq Order::SUBMITTED
        expect(order.commission_fee_cents).to eq 800_00
        expect(order.state_updated_at).not_to be_nil
        expect(order.state_expires_at).to eq(order.state_updated_at + 2.days)
        expect(order.reload.transactions.last.external_id).not_to be_nil
        expect(order.reload.transactions.last.transaction_type).to eq Transaction::HOLD
      end
    end
  end
end
