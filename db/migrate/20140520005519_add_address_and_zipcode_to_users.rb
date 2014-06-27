class AddAddressAndZipcodeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :address, :string
    add_column :users, :zipcode, :string
  end
end
