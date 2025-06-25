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

  def download_pdf
    @total_urls = Url.count
    @analyzed_urls = Url.joins(:sentiment_analyses).distinct.count
    @pending_urls = @total_urls - @analyzed_urls

    @sentiment_breakdown = SentimentAnalysis.group(:sentiment).count

    @recent_analyses = SentimentAnalysis.includes(:url)
                                      .order(created_at: :desc)
                                      .limit(10)

    respond_to do |format|
      format.pdf do
        pdf = Prawn::Document.new(page_size: "A4", margin: [ 20, 20, 20, 20 ])

        # Header
        pdf.font_size(24) { pdf.text "Sentiment Analysis Report", style: :bold, align: :center }
        pdf.move_down 10
        pdf.font_size(14) { pdf.text "Solar Energy Sentiment Analyzer", align: :center }
        pdf.font_size(12) { pdf.text "Overview of sentiment analysis data and insights", align: :center, color: "666666" }
        pdf.move_down 20

        # Summary section
        pdf.font_size(16) { pdf.text "Summary", style: :bold }
        pdf.move_down 10

        summary_data = [
          [ "Total URLs", @total_urls.to_s ],
          [ "Analyzed", @analyzed_urls.to_s ],
          [ "Pending", @pending_urls.to_s ]
        ]

        pdf.table(summary_data, width: pdf.bounds.width) do
          cells.style(size: 12, padding: [ 5, 10 ])
          row(0).style(background_color: "f0f0f0", font_style: :bold)
        end
        pdf.move_down 20

        # Sentiment Chart
        if @sentiment_breakdown.any?
          pdf.font_size(16) { pdf.text "Sentiment Analysis Overview", style: :bold }
          pdf.move_down 10

          # Chart origin and dimensions
          chart_width = pdf.bounds.width - 40
          chart_height = 200
          chart_origin_x = 20
          chart_origin_y = pdf.cursor
          bar_width = chart_width / @sentiment_breakdown.length
          max_value = @sentiment_breakdown.values.max

          # Draw chart bounding box
          pdf.stroke_rectangle [ chart_origin_x, chart_origin_y ], chart_width, chart_height

          # Draw bars and labels
          @sentiment_breakdown.each_with_index do |(sentiment, count), index|
            bar_height = (count.to_f / max_value) * (chart_height - 40)
            bar_x = chart_origin_x + index * bar_width + 5
            bar_y = chart_origin_y - 20 - (chart_height - 40 - bar_height)

            # Color coding for sentiments
            case sentiment
            when "positive"
              pdf.fill_color "4ade80" # green
            when "negative"
              pdf.fill_color "f87171" # red
            when "neutral"
              pdf.fill_color "fbbf24" # yellow
            else
              pdf.fill_color "6b7280" # gray
            end

            pdf.fill_rectangle [ bar_x, bar_y ], bar_width - 10, bar_height
            pdf.fill_color "000000"

            # Value label on top of bar
            pdf.font_size(10) do
              label_x = bar_x + (bar_width - 10) / 2
              # Position label just above the bar, accounting for text height
              label_y = bar_y + bar_height - 2
              # Ensure label doesn't go above chart top (accounting for text height)
              if label_y > chart_origin_y - 15
                label_y = chart_origin_y - 15
              end
              pdf.draw_text count.to_s, at: [ label_x, label_y ]
            end

            # Sentiment label below bar
            pdf.font_size(10) do
              label_x = bar_x + (bar_width - 10) / 2 - 20
              label_y = chart_origin_y - chart_height + 10
              pdf.draw_text sentiment.capitalize, at: [ label_x, label_y ]
            end
          end

          # Move cursor below the chart
          pdf.move_cursor_to(chart_origin_y - chart_height - 30)
          pdf.move_down 20
        end

        # Sentiment Distribution Table
        pdf.font_size(16) { pdf.text "Sentiment Distribution", style: :bold }
        pdf.move_down 10

        if @sentiment_breakdown.any?
          sentiment_data = [ [ "Sentiment", "Count" ] ]
          @sentiment_breakdown.each do |sentiment, count|
            sentiment_data << [ sentiment.capitalize, count.to_s ]
          end

          pdf.table(sentiment_data, width: pdf.bounds.width) do
            cells.style(size: 12, padding: [ 5, 10 ])
            row(0).style(background_color: "f0f0f0", font_style: :bold)
          end
        else
          pdf.text "No sentiment analysis data available yet.", color: "666666"
        end
        pdf.move_down 20

        # Recent Analyses
        pdf.font_size(16) { pdf.text "Recent Analyses", style: :bold }
        pdf.move_down 10

        if @recent_analyses.any?
          @recent_analyses.each do |analysis|
            pdf.font_size(12) { pdf.text analysis.url.url, style: :bold, color: "0066cc" }
            pdf.font_size(10) { pdf.text "Sentiment: #{analysis.sentiment.capitalize}", color: "666666" }
            pdf.font_size(10) { pdf.text "Date: #{analysis.created_at.strftime("%B %d, %Y at %I:%M %p")}", color: "666666" }
            pdf.move_down 10
          end
        else
          pdf.text "No recent analyses available.", color: "666666"
        end

        # Footer
        pdf.move_down 20
        pdf.font_size(10) { pdf.text "Generated on #{Date.current.strftime("%B %d, %Y")} at #{Time.current.strftime("%I:%M %p")}", align: :center, color: "666666" }
        pdf.font_size(10) { pdf.text "Solar Energy Sentiment Analyzer - Reports & Analytics", align: :center, color: "666666" }

        send_data pdf.render,
                  filename: "sentiment_analysis_report_#{Date.current.strftime('%Y%m%d')}.pdf",
                  type: "application/pdf",
                  disposition: "attachment"
      end
    end
  end
end
