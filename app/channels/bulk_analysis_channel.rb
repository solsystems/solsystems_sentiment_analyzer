class BulkAnalysisChannel < ApplicationCable::Channel
  def subscribed
    Rails.logger.info "=== BULK ANALYSIS CHANNEL SUBSCRIBED ==="
    Rails.logger.info "Streaming from: bulk_analysis"

    stream_from "bulk_analysis"
    Rails.logger.info "Successfully subscribed to bulk_analysis"
  end

  def unsubscribed
    Rails.logger.info "=== BULK ANALYSIS CHANNEL UNSUBSCRIBED ==="
  end
end
