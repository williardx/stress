class CreateOrderHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :order_histories do |t|
      t.references :order, foreign_key: true
      t.string :modifier_id, null: false
      t.jsonb :changed_fields, null: false
      t.timestamps
    end
  end
end
