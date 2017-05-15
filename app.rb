require 'sinatra'
require 'line/bot'

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

def get_lineids(names)
  ids = []
  # USER_ID_MAP {"lineid" => ["name1", "name2"], "lineid2" => ["name1"]}
  user_id_map = eval(ENV["USER_ID_MAP"])
  if names.each do |name|
    ids = user_id_map.select{ | k, v | v.include?(name) }.keys
  end.none?
    ids = user_id_map.keys 
  end
  ids
end

def push(message, *ids)
  message = {
    type: 'text',
    text: message.to_s
  }
  get_lineids(ids).each{ |id|
    puts "Push to #{id} #{message}"
    client.push_message(id,message)
  }
end

post '/line' do
  body = request.body.read
  useragent = request.user_agent.to_s
  body_json = JSON.parse(body)

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

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
            text: "useragent : " + useragent
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

post '/backlog' do
  BACKLOG_URL="https://#{ENV["BACKLOG_SPACENAME"]}.backlog.jp"
  
  puts "Called Backlog!!"
  body = request.body.read
  body_json = JSON.parse(body)
  # https://developer.nulab-inc.com/ja/docs/backlog/api/2/get-recent-updates/
  # 最近の更新の種別：
  # 1:課題の追加
    # * 新しい課題の追加
    # * 課題のアサイン 
  # 2:課題の更新
    # * 課題の更新
    # * 課題のアサイン 
  # 3:課題にコメント
    # * 課題にコメント
  # 4:課題の削除
    # * 課題の削除 
  # 5:Wikiを追加
    # * Wikiの追加
  # 6:Wikiを更新
    # * Wikiの更新 
  # 7:Wikiを削除
    # * Wikiの削除
  # 8:共有ファイルを追加
  # 9:共有ファイルを更新
  # 10:共有ファイルを削除
  # 11:Subversionコミット
  # 12:GITプッシュ
  # 13:GITリポジトリ作成
  # 14:課題をまとめて更新
  # 15:プロジェクトに参加
  # 16:プロジェクトから脱退
  # 17:コメントにお知らせを追加
  # 18:プルリクエストの追加
  # 19:プルリクエストの更新
  # 20:プルリクエストにコメント
  # 21:プルリクエストの削除
  # 22:マイルストーンの追加
  # 23:マイルストーンの更新
  # 24:マイルストーンの削除

  projectkey = body_json["project"]["projectKey"]
  projectname = body_json["project"]["name"]

  case body_json['type']
  when 1 then
    ticket_id = body_json["content"]["key_id"]
    title =  body_json["content"]["summary"]
    description = body_json["content"]["description"]
    assignee = body_json["content"]["assignee"]["name"]
    by_user = body_json["createdUser"]["name"]
    url = "#{BACKLOG_URL}/view/#{projectkey}-#{ticket_id}"
    message = "(ΦωΦ) [課題追加]#{projectname} #{title} #{description} by #{by_user} #{url}"
    push(message)

    message = "(ΦωΦ) [アサイン]#{projectname} #{title} #{assignee}にアサインしたよ！ #{url}"
    push(message,"#{assignee}")

  when 2 then
    ticket_id = body_json["content"]["key_id"]
    title =  body_json["content"]["summary"]
    assignee = body_json["content"]["changes"].select{|change| change["field"]=="assigner"}[0]["new_value"]
    by_user = body_json["createdUser"]["name"]
    url = "#{BACKLOG_URL}/view/#{projectkey}-#{ticket_id}"

    message = "(ΦωΦ) [課題更新]#{projectname} #{title} 更新があったよ！ by #{by_user} #{url}"
    push(message)
    message = "(ΦωΦ) [アサイン]#{projectname} #{title} *#{assignee}にアサインしたよ！ #{url}"
    push(message,"#{assignee}")

  when 3 then
    ticket_id = body_json["content"]["key_id"]
    title =  body_json["content"]["summary"]
    comment = body_json["content"]["comment"]["content"]
    by_user = body_json["createdUser"]["name"] 
    url = "#{BACKLOG_URL}/view/#{projectkey}-#{ticket_id}"

    message = "(ΦωΦ) [コメント]#{projectname} #{title} #{comment} by #{by_user} #{url}"
    push(message)
  when 4 then
    ticket_id = body_json["content"]["key_id"]
    title =  body_json["content"]["summary"]
    by_user = body_json["createdUser"]["name"] 
    url = "#{BACKLOG_URL}/view/#{projectkey}-#{ticket_id}"
    
    message = "(ΦωΦ) [課題削除]#{projectname} #{title} が削除されました by #{by_user}"
    push(message)

  # wiki
  when 5 then
    page = body_json["content"]["name"]
    by_user = body_json["createdUser"]["name"]
    url = "#{BACKLOG_URL}/wiki/#{projectkey}/#{page}"

    message = "(ΦωΦ) [Wiki追加]#{projectname} #{page} by #{by_user} #{url}"
    push(message)

  when 6 then
    page = body_json["content"]["name"]
    by_user = body_json["createdUser"]["name"]
    url = "#{BACKLOG_URL}/wiki/#{projectkey}/#{page}"
    
    message = "(ΦωΦ) [Wiki更新]#{projectname} #{page} by #{by_user} #{url}"
    push(message)

  when 7 then
    page = body_json["content"]["name"]
    by_user = body_json["createdUser"]["name"]
    url = "#{BACKLOG_URL}/wiki/#{projectkey}/#{page}"
    
    message = "(ΦωΦ) [Wiki削除]#{projectname} #{page} by #{by_user}"
    push(message)

  # その他
  else
    puts " nothing case"
  end

  "OK"
end
