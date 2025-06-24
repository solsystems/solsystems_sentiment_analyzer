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

    if response.is_a?(Net::HTTPSuccess)
      html_content = response.body
      doc = Nokogiri::HTML(html_content)

      # First, try to find content within <article> tags
      article_content = doc.css("article p").map(&:text).join(" ").strip

      if article_content.present?
        # If we found content in <article> tags, use that
        article_content
      else
        # If no <article> tags or no content in them, extract all <p> tags
        doc.css("p").map(&:text).join(" ").strip
      end
    else
      nil
    end
  rescue => e
    nil
  end
end
