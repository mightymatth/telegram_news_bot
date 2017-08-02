require 'telegram/bot'
require_relative 'utils/telegram_helpers'


STDOUT.sync = true

# Telegram Bot commands:
#
# popular - Most Popular
# new - Most Recent
# croatia - Croatia
# world - World

TOKEN = '395558391:AAGAyg3EUoPYsl41TmhsKaBcEX7sY5RlRsc' # Net.hr Matth Bot
# TOKEN = '435224023:AAGU8pcQMqb-zRsIbzLl3inSEq8RpRl0ZFk' # Net.hr Test Bot

RHASH = '6919fd5eeb20f4' # Telegram Net.hr template
UPDATE_INTERVAL = 5 * 60 # in seconds

class TgNewsBot
  extend TelegramHelpers

  update_sections
  set_update_timer(UPDATE_INTERVAL)


  @options = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: [['Most Popular', 'Most Recent'], ['Croatia', 'World']],
      one_time_keyboard: true)

  Telegram::Bot::Client.run(TOKEN) do |bot|
    bot.listen do |message|
      case message.text
        when '/start'
          welcome = 'Welcome to Net.hr Bot made by @mpevec'
          bot.api.send_message(chat_id: message.chat.id, text: welcome, reply_markup: @options)
        when '/stop'
          bot.api.send_message(chat_id: message.chat.id, text: 'Sorry to see you go :(')
        when 'Most Popular', '/popular'
          log_sending('Most Popular', message.from)
          Section.get(:most_popular).each do |link|
            send_link_preview_message(bot, message.chat.id, link)
          end
        when 'Most Recent', '/new'
          log_sending('Most Recent', message.from)
          Section.get(:newest).each do |link|
            send_link_preview_message(bot, message.chat.id, link)
          end
        when 'Croatia', '/croatia'
          log_sending('Croatia', message.from)
          Section.get(:croatia).each do |link|
            send_link_preview_message(bot, message.chat.id, link)
          end
        when 'World', '/world'
          log_sending('World', message.from)
          Section.get(:world).each do |link|
            send_link_preview_message(bot, message.chat.id, link)
          end
        else
          bot.api.send_message(chat_id: message.chat.id, text: 'Unknown command.', reply_markup: @options)
      end
    end
  end
end
