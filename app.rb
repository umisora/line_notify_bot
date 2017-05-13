require 'sinatra'
require 'line/bot'

TARGET_IDS = []
# 32文字
get '/' do
  "Hello world"
end

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

def push(message)
  ENV['TARGET_IDS'].split(",").each{ |id|
    client.push_message(id,message)
    TARGET_IDS.push(line_id) 
  }
end

post '/callback' do
  referrer = request.referrer.to_s
  useragent = request.user_agent.to_s
  body = request.body.read
  body_json = JSON.parse(body)
  #signature = request.env['HTTP_X_LINE_SIGNATURE']
  #unless client.validate_signature(body, signature)
  #  error 400 do 'Bad Request' end
  #end

  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        if event.message['text'].include?('id')
          message = {
            type: 'text',
            text: 'Your User ID is :' + body_json["events"][0]["source"]["userId"].to_s
          }
        elsif event.message['text'].include?('agent')
          message = {
            type: 'text',
            text: "referrer : " + referrer + "|| useragent : " + useragent
          }
        else 
          message = {
            type: 'text',
            text: event.message['text']
          }
        end
        client.reply_message(event['replyToken'], message)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
      end
    end
  }

  "OK"
end
