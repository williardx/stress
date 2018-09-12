require 'rails_helper'

describe PostSalesTaxRefundJob, type: :job do
  let(:order) { Fabricate(:order, fulfillment_type: Order::SHIP, shipping_country: 'US', shipping_postal_code: '10013', shipping_region: 'NY', shipping_city: 'New York', shipping_address_line1: '401 Broadway', shipping_total_cents: 100) }
  let(:shipping) do
    {
      country: order.shipping_country,
      postal_code: order.shipping_postal_code,
      region: order.shipping_region,
      city: order.shipping_city,
      address_line1: order.shipping_address_line1
    }
  end
  let!(:line_item) { Fabricate(:line_item, order: order) }
  let(:artwork_location) { gravity_v1_artwork[:location] }
  let(:refund_date) { Time.new(2018, 1, 1) }
  describe '#perform' do
    it 'instantiates a new SalesTaxService and calls refund_transaction' do
      sales_tax_instance = double
      expect(SalesTaxService).to receive(:new).with(line_item, order.fulfillment_type, shipping, order.shipping_total_cents, artwork_location).and_return(sales_tax_instance)
      expect(sales_tax_instance).to receive(:refund_transaction).with(refund_date)
      expect(GravityService).to receive(:get_artwork).with(line_item.artwork_id).and_return(gravity_v1_artwork)
      PostSalesTaxRefundJob.perform_now(line_item.id, refund_date)
    end
  end
end
