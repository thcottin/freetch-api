class RenamePaymentTokenToCustomerToken < ActiveRecord::Migration
  def change
    rename_column :users, :payment_token, :customer_token
  end
end
