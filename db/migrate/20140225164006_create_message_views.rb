class CreateMessageViews < ActiveRecord::Migration
  def change
    create_table :message_views do |t|
      t.string :ref
      t.string :message

      t.timestamps
    end
  end
end
