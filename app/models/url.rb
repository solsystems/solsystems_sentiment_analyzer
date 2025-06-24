class Url < ApplicationRecord
  validates :url, presence: true, uniqueness: true
  validates :url, format: { with: URI.regexp(%w[http https]), message: "must be a valid URL" }

  has_many :sentiment_analyses, dependent: :destroy

  def latest_analysis
    sentiment_analyses.order(created_at: :desc).first
  end

  def analyzed?
    sentiment_analyses.exists?
  end
end
