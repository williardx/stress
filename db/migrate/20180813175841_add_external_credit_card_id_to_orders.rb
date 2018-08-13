class AddExternalCreditCardIdToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :external_credit_card_id, :string
  end
end
