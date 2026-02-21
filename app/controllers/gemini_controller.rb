class GeminiController < ApplicationController

  def define
    text = params[:text].to_s.strip

    if text.blank?
      render json: { html: "<p class='text-danger'>No text provided.</p>" }
      return
    end

    prompt = "Give a clear, concise, and engaging definition of this text. Keep it natural and under 50 words:\n\n\"#{text}\""

    response_text = call_gemini_text(prompt)

    if response_text.present?
      render json: { html: "<div class='gemini-response p-3 border rounded bg-light'>#{response_text}</div>" }
    else
      render json: { html: "<p class='text-danger'>Gemini returned no response.</p>" }
    end
  end



  def imagine
    text = params[:text].to_s.strip

    if text.blank?
      render json: { html: "<p class='text-danger'>No text provided.</p>" }
      return
    end

    # Much better prompt for Imagen
    improved_prompt = "Create a beautiful, high-quality, cinematic image inspired by this text: \"#{text}\". 
                      Style: vibrant colors, detailed, artistic, dramatic lighting, professional photography, 
                      highly detailed."

    image_url = call_imagen(prompt: improved_prompt)

    if image_url
      render json: { html: "<img src='#{image_url}' class='img-fluid rounded shadow' alt='Imagination'>" }
    else
      render json: { html: "<p class='text-danger'>Sorry, could not generate image.</p>" }
    end
  end



  private

  def call_gemini_text(prompt)
    api_key = ENV['GEMINI_API_KEY']

    if api_key.blank?
      return "Error: API key is not configured."
    end

    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{api_key}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"

    request.body = {
      contents: [{
        parts: [{ text: prompt }]
      }],
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 1000,        # ← Increased
        topP: 0.95,
        topK: 64
      },
      safetySettings: [
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE" }
      ]
    }.to_json

    response = http.request(request)

    if response.code == "200"
      json = JSON.parse(response.body)
      text = json.dig("candidates", 0, "content", "parts", 0, "text") || "No response."
      
      # Clean up any trailing incomplete sentence
      text = text.gsub(/\s+\w+$/, '') if text.end_with?(' or', ' and', ' the', ' a ', ' an ')
      
      text
    else
      "API Error: #{response.code}"
    end
  rescue => e
    "Error: #{e.message}"
  end



  def call_imagen(prompt:)
    api_key = ENV['GEMINI_API_KEY']
    return nil if api_key.blank?

    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/imagen-4.0-generate-001:predict?key=#{api_key}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"

    request.body = {
      instances: [
        {
          prompt: prompt
        }
      ],
      parameters: {
        sampleCount: 1,
        aspectRatio: "1:1"
      }
    }.to_json

    response = http.request(request)

    if response.code == "200"
      json = JSON.parse(response.body)
      base64 = json.dig("predictions", 0, "bytesBase64Encoded")
      base64 ? "data:image/png;base64,#{base64}" : nil
    else
      Rails.logger.error "Imagen HTTP Error: #{response.code} - #{response.body}"
      nil
    end
  rescue => e
    Rails.logger.error "Imagen Exception: #{e.message}"
    nil
  end

end