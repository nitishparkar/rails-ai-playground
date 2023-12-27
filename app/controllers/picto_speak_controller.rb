class PictoSpeakController < ApplicationController
  def home
  end

  def execute
    service = ActiveStorage::Blob.service
    service.upload(params['picture'].original_filename, params['picture'])

    base64_image = Base64.encode64(File.read(params['picture'].tempfile))

    messages = [
      { "type": "text", "text": "What’s in this image?"},
      { "type": "image_url",
        "image_url": {
          "url": "data:image/jpeg;base64,#{base64_image}",
        },
      }
    ]
    client = OpenAI::Client.new
    response = client.chat(
        parameters: {
            model: "gpt-4-vision-preview", # Required.
            messages: [{ role: "user", content: messages}], # Required.
        })


    text =  response.dig("choices", 0, "message", "content")

    response = client.audio.speech(
      parameters: {
        model: "tts-1",
        input: text,
        voice: "nova"
      }
    )

    # mp3_name = SecureRandom.hex + '.mp3'
    # service.upload(mp3_name, StringIO.new(response))
    # puts "wrote to #{mp3_name}"

    # send_data response, filename: 'preview.mp3', type: 'audio/mp3', disposition: 'inline'

    # file_path = Rails.root.join('demo.mp3')
    # response = File.binread(file_path)

    encoded_audio_data = Base64.strict_encode64(response)
    render turbo_stream: turbo_stream.replace('audio_container', partial: 'audio_player', locals: { audio_data: encoded_audio_data })
  end
end