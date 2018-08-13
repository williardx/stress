class AddExternalCustomerIdToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :external_customer_id, :string
  end
end
