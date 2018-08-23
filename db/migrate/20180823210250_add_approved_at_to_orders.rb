class AddApprovedAtToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :approved_at, :datetime
  end
end
