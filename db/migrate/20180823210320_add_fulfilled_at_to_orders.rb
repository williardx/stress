class AddFulfilledAtToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :fulfilled_at, :datetime
  end
end
