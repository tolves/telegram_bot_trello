# encoding: utf-8
require 'telegram/bot'
require 'json'
require 'uri'
require '/home/bot/json_save.rb'
token = 'token'
incompleteLabels = ['5666779e19ad3a5dc26426a5', '57287baf9148b133b928f6da', '56d4fd5d152c3f92fd3a75c7', '574c64565b9b3323fb39a5bd']
begin
  Telegram::Bot::Client.run(token, logger: Logger.new($stderr)) do |bot|
    bot.logger.info('Bot has been started')
    bot.listen do |message|
      case message
        when Telegram::Bot::Types::InlineQuery
          if message.query == '' || message.query.length < 2 || message.query.include?(' ')
            next
          end
          title = message.query.downcase.to_s
          trello = open('/home/bot/ingress-medal-arts.json').read
          json = JSON.parser.new(trello)
          hash = json.parse()
          mission_title = Array.new
          uniq_title = Array.new
          cards_hash = hash['cards']
          result =''
          cover_url = ''
          results = Array.new
          cards_hash.each_with_index { |value, key|
            target_name = value['name'].downcase.to_s
            if (target_name.include?(title)) && (value['closed'] != true)
              cover_url ||= ''
              if value['idAttachmentCover'] != nil
                value['attachments'].each do |attachment|
                  if attachment['id'] == value['idAttachmentCover']
                    cover_url = !attachment['previews'][4].nil? ? attachment['previews'][4]['url'] : attachment['url']
                    break
                  end
                end
              end
              labal = Array.new
              if value['idLabels'] != nil
                value['labels'].each do |item|
                  labal.push(item['name'])
                end
              end
              name = value['name'].sub(/^\[.*\]( |)/, "")
              results.push([name, value['desc'], value['shortUrl'], cover_url, labal])
            end
          }
          final = Array.new
          next if results.length < 1
          results.each_with_index do |arr, index|
            #这里有一个问题，telegram不允许发送过长的inline内容，如果允许显示内容过多，会导致413出错
            break if index>3

            text = "[|](#{arr[3]}) | [#{arr[0]}](#{arr[2]}) \n"
            text << "[ingressmm](#{URI::escape("http://ingressmm.com/?find=#{arr[0]}")})\t"
            text << "[AQMH](http://aqmh.azurewebsites.net/#q=#{URI::escape(arr[0])})\t"
            text << "[IngressMosaic](https://ingressmosaik.com/mosaic/#{URI::escape(arr[0])})\n"
            #如果源中不符合md规范，很容易造成崩溃，干脆注释掉
#          text << arr[1]

            content = Telegram::Bot::Types::InputTextMessageContent.new(
                message_text: text,
                parse_mode: "Markdown",
                disable_web_page_preview: false
            )

            final.push(
                Telegram::Bot::Types::InlineQueryResultArticle.new(
                    id: index,
                    title: arr[0],
                    input_message_content: content,
                    thumb_url: arr[3]=='' ? 'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_120x44dp.png' : arr[3],
                    hide_url: true,
                    description: arr[4].map { |i| i+"\n" }.to_s
                )
            )
          end
          bot.api.answer_inline_query(inline_query_id: message.id, results: final)
      end
    end
  end
rescue
  puts '又出错一次啦,人家先睡10s喔'
  sleep(10)
  retry
end
