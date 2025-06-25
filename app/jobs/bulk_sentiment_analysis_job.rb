class BulkSentimentAnalysisJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting BulkSentimentAnalysisJob"

    # Get URLs that don't have any sentiment analyses yet
    urls = Url.left_outer_joins(:sentiment_analyses).where(sentiment_analyses: { id: nil })
    total_urls = urls.count
    processed_count = 0

    Rails.logger.info "Found #{total_urls} URLs to analyze (only URLs without existing analyses)"

    if total_urls == 0
      Rails.logger.info "No URLs need analysis - all URLs already have sentiment analyses"
      return
    end

    Rails.logger.info "URLs to be analyzed:"
    urls.each { |url| Rails.logger.info "  - #{url.url}" }

    urls.find_each do |url|
      begin
        Rails.logger.info "Analyzing URL #{url.id}: #{url.url}"

        # Create sentiment analysis for this URL (replaces any existing analyses)
        sentiment_analysis = url.create_single_analysis
        sentiment_analysis.analyze_sentiment
        sentiment_analysis.save!

        processed_count += 1
        Rails.logger.info "Successfully analyzed URL #{url.id} (#{processed_count}/#{total_urls})"

        # Broadcast progress to all connected clients
        percentage = ((processed_count.to_f / total_urls) * 100).round(1)
        Rails.logger.info "Broadcasting progress: #{processed_count}/#{total_urls} (#{percentage}%) - Current URL: #{url.url}"

        begin
          ActionCable.server.broadcast(
            "bulk_analysis",
            {
              type: "progress",
              processed: processed_count,
              total: total_urls,
              percentage: percentage,
              current_url: url.url
            }
          )
          Rails.logger.info "Successfully broadcasted progress update"
        rescue => e
          Rails.logger.error "Error broadcasting progress update: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      rescue => e
        Rails.logger.error "Error analyzing URL #{url.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # Continue with next URL even if one fails
      end
    end

    # Send completion notification
    Rails.logger.info "Broadcasting completion"
    begin
      ActionCable.server.broadcast(
        "bulk_analysis",
        {
          type: "complete",
          processed: processed_count,
          total: total_urls,
          message: "Bulk analysis complete! #{processed_count} URLs analyzed."
        }
      )
      Rails.logger.info "Successfully broadcasted completion"
    rescue => e
      Rails.logger.error "Error broadcasting completion: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end

    Rails.logger.info "BulkSentimentAnalysisJob completed. Processed #{processed_count}/#{total_urls} URLs"
  end
end
