require 'telegram/bot'
require 'nokogiri'
require 'open-uri'
require 'concurrent'

STDOUT.sync = true

# Telegram Bot commands:
#
# popular - Most Popular
# new - Most Recent
# croatia - Croatia
# world - World

# token = '395558391:AAGAyg3EUoPYsl41TmhsKaBcEX7sY5RlRsc' # Net.hr Matth Bot
token = '435224023:AAGU8pcQMqb-zRsIbzLl3inSEq8RpRl0ZFk' # Net.hr Test Bot

@rhash = '6919fd5eeb20f4' # Telegram Net.hr template
update_interval = 5 * 60 # in seconds

def get_telegram_link(url, rhash)
  uri = URI.parse('https://t.me/iv')
  uri.query = URI.encode_www_form({url: url, rhash: rhash})
  uri.to_s
end

def send_link_preview_message(bot, chat_id, link)
  html_link = "[»](#{link})"
  bot.api.send_message(chat_id: chat_id, text: html_link,
                       parse_mode: 'Markdown',
                       reply_markup: {hide_keyboard: true})
end

def update
  Concurrent::Promise.fulfill(Nokogiri::HTML(open('http://www.net.hr'))).then {|page|
    puts "[#{Time.now}] Fetched #{page.title}"
    @most_popular = page.css('div.tab_1 a').map {|link| get_telegram_link(link.values[0], @rhash)}
    @newest = page.css('div.tab_2 a').map {|link| get_telegram_link(link.values[0], @rhash)}
  }.execute

  Concurrent::Promise.fulfill(Nokogiri::HTML(open('http://net.hr/kategorija/danas/hrvatska/'))).then {|page|
    puts "[#{Time.now}] Fetched #{page.title}"
    @croatia = page.css('section.feed.cf article.article-feed').map {|article|
      get_telegram_link(article.css('div.article-text a')[0].values[0], @rhash)
    }
  }.execute

  Concurrent::Promise.fulfill(Nokogiri::HTML(open('http://net.hr/kategorija/danas/svijet/'))).then {|page|
    puts "[#{Time.now}] Fetched #{page.title}"
    @world = page.css('section.feed.cf article.article-feed').map {|article|
      get_telegram_link(article.css('div.article-text a')[0].values[0], @rhash)
    }
  }.execute
end

update
Concurrent::TimerTask.new(execution_interval: update_interval) {update}.execute


@options = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
    keyboard: [['Most Popular', 'Most Recent'], ['Croatia', 'World']],
    one_time_keyboard: true)

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message.text
      when '/start'
        welcome = 'Welcome to Net.hr Bot made by @mpevec'
        bot.api.send_message(chat_id: message.chat.id, text: welcome, reply_markup: @options)
      when '/stop'
        bot.api.send_message(chat_id: message.chat.id, text: 'Sorry to see you go :(')
      when 'Most Popular', '/popular'
        puts "[#{Time.now}] Sending 'Most Popular' to #{message.from.first_name} #{message.from.last_name} (#{message.from.username})"
        @most_popular.each do |link|
          send_link_preview_message(bot, message.chat.id, link)
        end
      when 'Most Recent', '/new'
        puts "[#{Time.now}] Sending 'Most Recent' to #{message.from.first_name} #{message.from.last_name} (#{message.from.username})"
        @newest.each do |link|
          send_link_preview_message(bot, message.chat.id, link)
        end
      when 'Croatia', '/croatia'
        puts "[#{Time.now}] Sending 'Croatia' to #{message.from.first_name} #{message.from.last_name} (#{message.from.username})"
        @croatia.each do |link|
          send_link_preview_message(bot, message.chat.id, link)
        end
      when 'World', '/world'
        puts "[#{Time.now}] Sending 'World' to #{message.from.first_name} #{message.from.last_name} (#{message.from.username})"
        @world.each do |link|
          send_link_preview_message(bot, message.chat.id, link)
        end
      else
        bot.api.send_message(chat_id: message.chat.id, text: 'Unknown command.', reply_markup: @options)
    end
  end
end
