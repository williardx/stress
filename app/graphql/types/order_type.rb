class Types::OrderType < Types::BaseObject
  description 'An Order'
  graphql_name 'Order'

  field :id, ID, null: false
  field :code, String, null: false
  field :user_id, String, null: false
  field :partner_id, String, null: false
  field :credit_card_id, String, null: true
  field :state, Types::OrderStateEnum, null: false
  field :currency_code, String, null: false
  field :fulfillment, Types::FulfillmentUnionType, null: true
  field :items_total_cents, Integer, null: false
  field :shipping_total_cents, Integer, null: true
  field :tax_total_cents, Integer, null: true
  field :transaction_fee_cents, Integer, null: true, seller_only: true
  field :commission_fee_cents, Integer, null: true, seller_only: true
  field :seller_total_cents, Integer, null: true, seller_only: true
  field :buyer_total_cents, Integer, null: true
  field :created_at, Types::DateTimeType, null: false
  field :updated_at, Types::DateTimeType, null: false
  field :state_updated_at, Types::DateTimeType, null: true
  field :state_expires_at, Types::DateTimeType, null: true
  field :line_items, Types::LineItemType.connection_type, null: true
  field :submitted_at, Types::DateTimeType, null: true
  field :approved_at, Types::DateTimeType, null: true
  field :rejected_at, Types::DateTimeType, null: true
  field :fulfilled_at, Types::DateTimeType, null: true

  def fulfillment
    # fulfillment is not a field on order so we have to resolve it here
    # it uses our union, for that to work we need to pass order (aka object)
    # to our Fulfillment
    object
  end
end
