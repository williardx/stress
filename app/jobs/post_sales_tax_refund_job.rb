class PostSalesTaxRefundJob < ApplicationJob
  queue_as :default

  def perform(line_item_id, refund_date)
    line_item = LineItem.find(line_item_id)
    artwork = GravityService.get_artwork(line_item.artwork_id)
    shipping = {
      country: line_item.order.shipping_country,
      postal_code: line_item.order.shipping_postal_code,
      region: line_item.order.shipping_region,
      city: line_item.order.shipping_city,
      address_line1: line_item.order.shipping_address_line1
    }
    SalesTaxService.new(line_item, line_item.order.fulfillment_type, shipping, line_item.order.shipping_total_cents, artwork[:location]).refund_transaction(refund_date)
  end
end
