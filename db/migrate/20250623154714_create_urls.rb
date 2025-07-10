class CreateUrls < ActiveRecord::Migration[8.0]
  def change
    create_table :urls do |t|
      t.string :url

      t.timestamps
    end
    add_index :urls, :url, unique: true
  end
end
