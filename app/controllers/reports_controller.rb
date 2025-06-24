class ReportsController < ApplicationController
  def index
    @total_urls = Url.count
    @analyzed_urls = Url.joins(:sentiment_analyses).distinct.count
    @pending_urls = @total_urls - @analyzed_urls

    @sentiment_breakdown = SentimentAnalysis.group(:sentiment).count

    @recent_analyses = SentimentAnalysis.includes(:url)
                                      .order(created_at: :desc)
                                      .limit(10)
  end
end
