class Mutations::FinalizeOrder < Mutations::BaseMutation
  null true

  argument :id, ID, required: true

  field :order, Types::OrderType, null: true
  field :errors, [String], null: false

  def resolve(id:)
    order = Order.find(id)
    validate_request!(order)
    {
      order: OrderService.finalize!(order, context[:current_user]['id']),
      errors: []
    }
  rescue Errors::ApplicationError => e
    { order: nil, errors: [e.message] }
  end

  def validate_request!(order)
    raise Errors::AuthError, 'Not permitted' unless context[:current_user]['partner_ids'].include?(order.partner_id)
  end
end
