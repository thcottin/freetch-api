class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.string :key
      t.string :value
    end
  end
end
