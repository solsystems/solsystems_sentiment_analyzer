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

  # Ensure only the most recent analysis is kept
  def create_single_analysis
    # Delete any existing analyses for this URL
    sentiment_analyses.destroy_all

    # Create a new analysis
    sentiment_analyses.build
  end
end
