class CreateSentimentAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :sentiment_analyses do |t|
      t.references :url, null: false, foreign_key: true
      t.string :sentiment
      t.text :reasoning

      t.timestamps
    end
  end
end
