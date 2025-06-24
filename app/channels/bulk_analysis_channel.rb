class BulkAnalysisChannel < ApplicationCable::Channel
  def subscribed
    stream_from "bulk_analysis_#{params[:session_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
