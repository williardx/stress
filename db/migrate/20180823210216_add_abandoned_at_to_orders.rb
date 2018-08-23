class AddAbandonedAtToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :abandoned_at, :datetime
  end
end
