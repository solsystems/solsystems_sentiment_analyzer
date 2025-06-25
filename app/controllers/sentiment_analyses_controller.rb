class SentimentAnalysesController < ApplicationController
  before_action :set_url, only: [ :create ]

  def create
    @sentiment_analysis = @url.create_single_analysis

    begin
      @sentiment_analysis.analyze_sentiment

      if @sentiment_analysis.save
        redirect_to @url, notice: "Sentiment analysis completed successfully."
      else
        redirect_to @url, alert: "Failed to save sentiment analysis."
      end
    rescue => e
      redirect_to @url, alert: "Sentiment analysis failed: #{e.message}"
    end
  end

  private

  def set_url
    @url = Url.find(params[:url_id])
  end
end
