class SentimentAnalysis < ApplicationRecord
  belongs_to :url

  validates :sentiment, presence: true, inclusion: { in: %w[positive negative neutral unclear] }
  validates :reasoning, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def sentiment_class
    case sentiment
    when "positive"
      "text-success"
    when "negative"
      "text-danger"
    when "neutral"
      "text-secondary"
    when "unclear"
      "text-warning"
    end
  end

  def analyze_sentiment
    result = self.class.analyze_sentiment_for_url(url.url)
    self.sentiment = result[:sentiment]
    self.reasoning = result[:reasoning]
  end

  def self.analyze_sentiment_for_url(url)
    # This is a placeholder for OpenAI integration
    # You'll need to add the openai gem and configure your API key
    client = OpenAI::Client.new(api_key: ENV["OPENAI_API_KEY"])

    # First, fetch the content from the URL
    content = fetch_url_content(url)

    if content.nil? || content.strip.empty?
      return { sentiment: "unclear", reasoning: "Could not fetch content from the URL. Please check if the URL is accessible." }
    end

    response = client.chat.completions.create(
      model: "gpt-3.5-turbo",
      messages: [
        {
          role: "system",
          content: "You are an expert sentiment analyst for the solar energy industry."
        },
        {
          role: "user",
          content: "Here is an article:\n\n#{content[0..2000]}\n\nPlease classify the sentiment of this article toward the solar energy industry as positive, negative, or neutral. Provide reasoning."
        }
      ],
      temperature: 0,
      max_tokens: 500
    )

    # Parse the response and extract sentiment and reasoning
    ai_response = response.choices.first.message.content

    # Try to parse JSON response
    begin
      parsed = JSON.parse(ai_response)
      { sentiment: parsed["sentiment"] || "unclear", reasoning: parsed["reasoning"] || ai_response }
    rescue JSON::ParserError
      # Fallback to simple text parsing if JSON parsing fails
      # Only look in the first sentence for sentiment keywords
      first_sentence = ai_response.split(/[.!?]/).first.to_s.strip.downcase

      if first_sentence.include?("positive")
        { sentiment: "positive", reasoning: ai_response }
      elsif first_sentence.include?("negative")
        { sentiment: "negative", reasoning: ai_response }
      elsif first_sentence.include?("neutral")
        { sentiment: "neutral", reasoning: ai_response }
      else
        { sentiment: "unclear", reasoning: ai_response }
      end
    end
  rescue => e
    { sentiment: "unclear", reasoning: "Analysis failed: #{e.message}" }
  end

  def self.fetch_url_content(url)
    require "net/http"
    require "uri"
    require "nokogiri"

    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    Rails.logger.info("AKT-- Content from url: #{url}")

    if response.is_a?(Net::HTTPSuccess)
      html_content = response.body
      doc = Nokogiri::HTML(html_content)

      # First, try to find content within <article> tags
      article_content = doc.css("article p").map(&:text).join(" ").strip

      if article_content.present?
        # If we found content in <article> tags, use that
        Rails.logger.info("AKT--Success article_content: #{article_content}")
        article_content
      else
        # If no <article> tags or no content in them, extract all <p> tags
        p_content = doc.css("p").map(&:text).join(" ").strip

        if p_content.present?
          Rails.logger.info("AKT--Success p_content: #{p_content}")
          # If we found content in <p> tags, use that
          p_content
        else
          Rails.logger.info("AKT--Success doc content: #{doc.text.strip}")
          # If no <p> tags either, extract text between all tags
          doc.text.strip
        end
      end
    else
      Rails.logger.warn("AKT--Warning response: #{response.to_hash}")
      # Fallback to Chromium browser scraping
      scrape_with_chromium(url)
    end
  rescue => e
    Rails.logger.error("AKT--Failure doc content: #{e.message}")
    # Try Chromium browser scraping as last resort
    scrape_with_chromium(url)
  end

  def self.scrape_with_chromium(url)
    require "selenium-webdriver"

    Rails.logger.info("AKT-- Attempting Chromium scraping for: #{url}")

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

    # Set Chrome binary path for Docker environment
    if ENV["CHROME_BIN"]
      options.binary = ENV["CHROME_BIN"]
      Rails.logger.info("AKT-- Using Chrome binary: #{ENV['CHROME_BIN']}")
    end

    begin
      if ENV["SELENIUM_REMOTE_URL"]
        Rails.logger.info("AKT-- Using remote Selenium at: #{ENV['SELENIUM_REMOTE_URL']}")
        driver = Selenium::WebDriver.for(:remote, url: ENV["SELENIUM_REMOTE_URL"], capabilities: options)
      else
        Rails.logger.info("AKT-- Using local Selenium driver")
        driver = Selenium::WebDriver.for(:chrome, options: options)
      end

      Rails.logger.info("AKT-- Navigating to URL: #{url}")
      driver.get(url)

      # Wait for page to load
      sleep(3)

      # Handle common Accept dialogs and popups
      handle_accept_dialogs(driver)

      # Get the page source after JavaScript execution
      html_content = driver.page_source
      doc = Nokogiri::HTML(html_content)

      # First, try to find content within <article> tags
      article_content = doc.css("article p").map(&:text).join(" ").strip

      if article_content.present?
        Rails.logger.info("AKT--Chromium success article_content: #{article_content}")
        article_content
      else
        # If no <article> tags or no content in them, extract all <p> tags
        p_content = doc.css("p").map(&:text).join(" ").strip

        if p_content.present?
          Rails.logger.info("AKT--Chromium success p_content: #{p_content}")
          # If we found content in <p> tags, use that
          p_content
        else
          Rails.logger.info("AKT--Chromium success doc content: #{doc.text.strip}")
          # If no <p> tags either, extract text between all tags
          doc.text.strip
        end
      end
    rescue => e
      Rails.logger.error("AKT--Chromium scraping failed: #{e.message}")
      Rails.logger.error("AKT--Chromium error backtrace: #{e.backtrace.join("\n")}")
      nil
    ensure
      if defined?(driver) && driver
        Rails.logger.info("AKT-- Closing Chrome driver...")
        driver.quit
      end
    end
  rescue => e
    Rails.logger.error("AKT--Chromium setup failed: #{e.message}")
    Rails.logger.error("AKT--Chromium setup error backtrace: #{e.backtrace.join("\n")}")
    nil
  end

  def self.handle_accept_dialogs(driver)
    Rails.logger.info("AKT-- Checking for Accept dialogs...")

    # Common selectors for Accept/Cookie consent buttons
    accept_selectors = [
      # Cookie consent buttons
      "button[data-testid*='accept']",
      "button[data-testid*='Accept']",
      "button[data-testid*='cookie']",
      "button[data-testid*='Cookie']",
      "button[data-testid*='consent']",
      "button[data-testid*='Consent']",

      # Common button text patterns
      "button:contains('Accept')",
      "button:contains('Accept All')",
      "button:contains('Accept Cookies')",
      "button:contains('I Accept')",
      "button:contains('OK')",
      "button:contains('Got it')",
      "button:contains('Continue')",
      "button:contains('Allow')",
      "button:contains('Allow All')",
      "button:contains('Agree')",
      "button:contains('I Agree')",

      # Common class patterns
      "button.accept",
      "button.accept-all",
      "button.cookie-accept",
      "button.consent-accept",
      "button.btn-accept",
      "button.btn-cookie",

      # Common ID patterns
      "button#accept",
      "button#accept-all",
      "button#cookie-accept",
      "button#consent-accept",

      # Link patterns
      "a:contains('Accept')",
      "a:contains('Accept All')",
      "a:contains('I Accept')",

      # Div patterns (sometimes buttons are divs)
      "div[role='button']:contains('Accept')",
      "div[role='button']:contains('Accept All')",
      "div[role='button']:contains('I Accept')",

      # More specific selectors
      "[data-cy='accept-cookies']",
      "[data-cy='accept-all']",
      "[data-cy='cookie-accept']",
      "[data-cy='consent-accept']",

      # GDPR related
      "[data-gdpr='accept']",
      "[data-gdpr='accept-all']",

      # Generic but common patterns
      "button[class*='accept']",
      "button[class*='Accept']",
      "button[class*='cookie']",
      "button[class*='Cookie']",
      "button[class*='consent']",
      "button[class*='Consent']",
      "button[id*='accept']",
      "button[id*='Accept']",
      "button[id*='cookie']",
      "button[id*='Cookie']",
      "button[id*='consent']",
      "button[id*='Consent']"
    ]

    accept_selectors.each do |selector|
      begin
        # Try to find elements by the selector
        elements = driver.find_elements(css: selector)

        # Also try to find elements by text content
        text_elements = driver.find_elements(xpath: "//button[contains(text(), 'Accept') or contains(text(), 'Accept All') or contains(text(), 'I Accept') or contains(text(), 'OK') or contains(text(), 'Got it') or contains(text(), 'Continue') or contains(text(), 'Allow') or contains(text(), 'Agree')]")

        # Also try to find elements by partial text match
        partial_text_elements = driver.find_elements(xpath: "//*[contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'accept') or contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'cookie') or contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'consent')]")

        all_elements = elements + text_elements + partial_text_elements

        all_elements.each do |element|
          begin
            # Check if element is visible and clickable
            if element.displayed? && element.enabled?
              Rails.logger.info("AKT-- Found Accept dialog button: #{element.text} (#{element.tag_name})")
              element.click
              Rails.logger.info("AKT-- Clicked Accept dialog button")
              sleep(1) # Wait a moment for the dialog to close
              return true
            end
          rescue => e
            Rails.logger.debug("AKT-- Could not click element: #{e.message}")
            next
          end
        end
      rescue => e
        Rails.logger.debug("AKT-- Error with selector #{selector}: #{e.message}")
        next
      end
    end

    Rails.logger.info("AKT-- No Accept dialogs found or all handled")
    false
  end
end
