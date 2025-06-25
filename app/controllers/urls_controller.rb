class UrlsController < ApplicationController
  before_action :set_url, only: [ :show, :edit, :update, :destroy ]

  def index
    @urls = Url.includes(:sentiment_analyses).order(created_at: :desc)
    @pending_urls_count = Url.left_outer_joins(:sentiment_analyses).where(sentiment_analyses: { id: nil }).count

    # Debug output
    Rails.logger.info "=== DEBUG: URLs Index ==="
    Rails.logger.info "Total URLs: #{@urls.count}"
    Rails.logger.info "Pending URLs count: #{@pending_urls_count}"
    Rails.logger.info "URLs with analyses: #{@urls.joins(:sentiment_analyses).count}"
    Rails.logger.info "URLs without analyses: #{@urls.left_outer_joins(:sentiment_analyses).where(sentiment_analyses: { id: nil }).count}"
    Rails.logger.info "========================"
  end

  def show
  end

  def new
    @url = Url.new
  end

  def create
    @url = Url.new(url_params)

    if @url.save
      redirect_to @url, notice: "URL was successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @url.update(url_params)
      redirect_to @url, notice: "URL was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @url.destroy
    redirect_to urls_url, notice: "URL was successfully deleted."
  end

  def delete_all
    # Delete all sentiment analyses first (due to foreign key constraints)
    SentimentAnalysis.delete_all
    # Then delete all URLs
    Url.delete_all

    redirect_to urls_url, notice: "All URLs and sentiment analyses have been deleted."
  end

  def export
    @urls = Url.includes(:sentiment_analyses).order(created_at: :desc)

    respond_to do |format|
      format.csv do
        csv_data = CSV.generate(headers: true) do |csv|
          csv << [ "URL", "Sentiment", "Reasoning", "Analyzed At", "Created At" ]

          @urls.each do |url|
            if url.analyzed?
              analysis = url.latest_analysis
              csv << [
                url.url,
                analysis.sentiment,
                analysis.reasoning,
                analysis.created_at.strftime("%Y-%m-%d %H:%M:%S"),
                url.created_at.strftime("%Y-%m-%d %H:%M:%S")
              ]
            else
              csv << [
                url.url,
                "Not Analyzed",
                "",
                "",
                url.created_at.strftime("%Y-%m-%d %H:%M:%S")
              ]
            end
          end
        end

        send_data csv_data,
                  filename: "urls_sentiment_analysis_#{Date.current.strftime('%Y%m%d')}.csv",
                  type: "text/csv"
      end
    end
  end

  def bulk_import
  end

  def bulk_analyze
    pending_urls = Url.left_outer_joins(:sentiment_analyses).where(sentiment_analyses: { id: nil }).count

    Rails.logger.info "Bulk analyze requested. Found #{pending_urls} URLs without sentiment analyses"

    if pending_urls == 0
      Rails.logger.info "No pending URLs to analyze - redirecting"
      redirect_to urls_path, notice: "All URLs have already been analyzed."
      return
    end

    # Log which URLs will be analyzed
    pending_url_list = Url.left_outer_joins(:sentiment_analyses).where(sentiment_analyses: { id: nil })
    Rails.logger.info "URLs that will be analyzed:"
    pending_url_list.each { |url| Rails.logger.info "  - #{url.url}" }

    # Enqueue the job for background processing
    Rails.logger.info "Enqueuing BulkSentimentAnalysisJob..."
    begin
      BulkSentimentAnalysisJob.perform_later
      Rails.logger.info "Successfully enqueued BulkSentimentAnalysisJob"
    rescue => e
      Rails.logger.error "Error enqueuing job: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to urls_path, alert: "Error starting bulk analysis: #{e.message}"
      return
    end

    redirect_to urls_path, notice: "Bulk analysis started! #{pending_urls} URLs will be analyzed in the background."
  end

  def process_bulk_import
    # Check if file was uploaded
    if params[:file].blank?
      redirect_to bulk_import_urls_path, alert: "Please select a file to upload."
      return
    end

    file = params[:file]

    # Validate file size (max 10MB)
    max_size = 10.megabytes
    if file.size > max_size
      redirect_to bulk_import_urls_path, alert: "File is too large. Maximum size allowed is #{max_size / 1.megabyte}MB."
      return
    end

    # Validate file extension
    file_extension = File.extname(file.original_filename).downcase
    allowed_extensions = [ ".csv", ".xls", ".xlsx" ]

    unless allowed_extensions.include?(file_extension)
      redirect_to bulk_import_urls_path,
                  alert: "Invalid file format. Please upload a CSV or Excel file (.csv, .xls, .xlsx). Received: #{file_extension}"
      return
    end

    # Validate file content type
    allowed_content_types = [
      "text/csv",
      "application/vnd.ms-excel",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    ]

    unless allowed_content_types.include?(file.content_type)
      redirect_to bulk_import_urls_path,
                  alert: "Invalid file content type. Please upload a valid CSV or Excel file. Received: #{file.content_type}"
      return
    end

    begin
      # Parse the spreadsheet and get URLs
      urls = parse_spreadsheet(file)

      # Validate that we got some data
      if urls.empty?
        redirect_to bulk_import_urls_path,
                    alert: "No URLs found in the file. Please ensure the file contains URLs in the first column."
        return
      end

      # Validate URLs before saving
      valid_urls = []
      invalid_urls = []
      duplicate_urls = []

      urls.each_with_index do |url_string, index|
        row_number = index + 1

        # Skip empty rows
        if url_string.blank?
          next
        end

        # Clean the URL
        cleaned_url = url_string.strip

        # Basic URL validation
        unless valid_url_format?(cleaned_url)
          invalid_urls << "Row #{row_number}: Invalid URL format - '#{cleaned_url}'"
          next
        end

        # Check for duplicates
        if Url.exists?(url: cleaned_url)
          duplicate_urls << "Row #{row_number}: URL already exists - '#{cleaned_url}'"
          next
        end

        valid_urls << cleaned_url
      end

      # Process valid URLs
      imported_count = 0
      save_errors = []

      valid_urls.each_with_index do |url_string, index|
        url = Url.new(url: url_string)
        if url.save
          imported_count += 1
        else
          save_errors << "Row #{index + 1}: #{url.errors.full_messages.join(', ')}"
        end
      end

      # Build response message
      messages = []

      if imported_count > 0
        messages << "Successfully imported #{imported_count} URL#{imported_count == 1 ? '' : 's'}."
      end

      if invalid_urls.any?
        messages << "Skipped #{invalid_urls.count} invalid URL#{invalid_urls.count == 1 ? '' : 's'}."
      end

      if duplicate_urls.any?
        messages << "Skipped #{duplicate_urls.count} duplicate URL#{duplicate_urls.count == 1 ? '' : 's'}."
      end

      if save_errors.any?
        messages << "Failed to save #{save_errors.count} URL#{save_errors.count == 1 ? '' : 's'}."
      end

      # Determine message type and content
      if imported_count > 0
        notice_message = messages.join(" ")
        if invalid_urls.any? || duplicate_urls.any? || save_errors.any?
          notice_message += " Check the logs for details."
        end

        redirect_to urls_path, notice: notice_message
      else
        error_details = []
        error_details.concat(invalid_urls.first(3)) if invalid_urls.any?
        error_details.concat(duplicate_urls.first(3)) if duplicate_urls.any?
        error_details.concat(save_errors.first(3)) if save_errors.any?

        if invalid_urls.count > 3 || duplicate_urls.count > 3 || save_errors.count > 3
          error_details << "... and more (see logs for complete details)"
        end

        redirect_to bulk_import_urls_path, alert: "No URLs were imported. #{error_details.join('; ')}"
      end

      # Log detailed information
      Rails.logger.info "=== BULK IMPORT RESULTS ==="
      Rails.logger.info "Total URLs in file: #{urls.count}"
      Rails.logger.info "Valid URLs: #{valid_urls.count}"
      Rails.logger.info "Invalid URLs: #{invalid_urls.count}"
      Rails.logger.info "Duplicate URLs: #{duplicate_urls.count}"
      Rails.logger.info "Successfully imported: #{imported_count}"
      Rails.logger.info "Save errors: #{save_errors.count}"

      if invalid_urls.any?
        Rails.logger.info "Invalid URLs:"
        invalid_urls.each { |error| Rails.logger.info "  #{error}" }
      end

      if duplicate_urls.any?
        Rails.logger.info "Duplicate URLs:"
        duplicate_urls.each { |error| Rails.logger.info "  #{error}" }
      end

      if save_errors.any?
        Rails.logger.info "Save errors:"
        save_errors.each { |error| Rails.logger.info "  #{error}" }
      end
      Rails.logger.info "=========================="

    rescue CSV::MalformedCSVError => e
      redirect_to bulk_import_urls_path,
                  alert: "Invalid CSV format: #{e.message}. Please check that your CSV file is properly formatted."
    rescue Roo::Error => e
      redirect_to bulk_import_urls_path,
                  alert: "Error reading Excel file: #{e.message}. Please ensure the file is not corrupted and is a valid Excel file."
    rescue => e
      Rails.logger.error "Unexpected error during bulk import: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to bulk_import_urls_path,
                  alert: "An unexpected error occurred while processing the file: #{e.message}. Please try again or contact support."
    end
  end

  private

  def valid_url_format?(url)
    # Basic URL validation - check if it looks like a URL
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def parse_spreadsheet(file)
    urls = []
    file_extension = File.extname(file.original_filename).downcase

    if file_extension == ".csv"
      require "csv"
      csv_text = file.read
      CSV.parse(csv_text, headers: true) do |row|
        urls << row[0] # Assume URLs are in the first column
      end
    else
      # Excel files (.xls, .xlsx)
      require "roo"
      spreadsheet = Roo::Spreadsheet.open(file.path)
      sheet = spreadsheet.sheet(0)

      # Skip header row and get all URLs from first column
      (2..sheet.last_row).each do |row_number|
        urls << sheet.cell(row_number, 1)
      end
    end

    urls.compact
  end

  def set_url
    @url = Url.find(params[:id])
  end

  def url_params
    params.require(:url).permit(:url)
  end
end
