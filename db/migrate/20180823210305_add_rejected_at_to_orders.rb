class AddRejectedAtToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :rejected_at, :datetime
  end
end
