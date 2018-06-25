class Mutations::SubmitOrder < Mutations::BaseMutation
  null true

  argument :id, ID, required: true
  argument :credit_card_id, String, required: true

  field :order, Types::OrderType, null: true
  field :errors, [String], null: false

  def resolve(id:, credit_card_id:)
    order = Order.find(id)
    validate_request!(order)
    {
      order: OrderService.submit!(order, context[:current_user]['id'], credit_card_id: credit_card_id),
      errors: []
    }
  rescue Errors::ApplicationError => e
    { order: nil, errors: [e.message] }
  end

  def validate_request!(order)
    raise Errors::AuthError, 'Not permitted' unless context[:current_user]['id'] == order.user_id
  end
end
