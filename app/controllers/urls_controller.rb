class UrlsController < ApplicationController
  before_action :set_url, only: [ :show, :edit, :update, :destroy ]

  def index
    @urls = Url.includes(:sentiment_analyses).order(created_at: :desc)
    @pending_urls_count = Url.left_outer_joins(:sentiment_analyses).where(sentiment_analyses: { id: nil }).count
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

    # Generate a unique session ID for this user
    session_id = SecureRandom.uuid
    Rails.logger.info "Generated session ID for bulk analysis: #{session_id}"

    # Store the session ID for the frontend to use
    session[:bulk_analysis_id] = session_id
    Rails.logger.info "Stored session ID in session: #{session[:bulk_analysis_id]}"

    # Enqueue the job for background processing
    BulkSentimentAnalysisJob.perform_later(session_id)

    redirect_to urls_path, notice: "Bulk analysis started! #{pending_urls} URLs will be analyzed in the background."
  end

  def process_bulk_import
    if params[:file].blank?
      redirect_to bulk_import_urls_path, alert: "Please select a file to upload."
      return
    end

    file = params[:file]
    file_extension = File.extname(file.original_filename).downcase

    unless [ ".csv", ".xls", ".xlsx" ].include?(file_extension)
      redirect_to bulk_import_urls_path, alert: "Please upload a CSV or Excel file (.csv, .xls, .xlsx)."
      return
    end

    begin
      urls = parse_spreadsheet(file)
      imported_count = 0
      errors = []

      urls.each_with_index do |url_string, index|
        next if url_string.blank?

        url = Url.new(url: url_string.strip)
        if url.save
          imported_count += 1
        else
          errors << "Row #{index + 1}: #{url.errors.full_messages.join(', ')}"
        end
      end

      if errors.any?
        redirect_to urls_path, alert: "Imported #{imported_count} URLs. Errors: #{errors.join('; ')}"
      else
        redirect_to urls_path, notice: "Successfully imported #{imported_count} URLs."
      end
    rescue => e
      redirect_to bulk_import_urls_path, alert: "Error processing file: #{e.message}"
    end
  end

  private

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
