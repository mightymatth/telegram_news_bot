require 'telegram/bot'
require 'dotenv/load'
require_relative 'utils/telegram_helpers'
require_relative 'utils/storage'

STDOUT.sync = true

# Telegram Bot commands:
#
# popular - Most Popular
# new - Most Recent
# croatia - Croatia
# world - World

# TOKEN = '395558391:AAGAyg3EUoPYsl41TmhsKaBcEX7sY5RlRsc' # Net.hr Matth Bot
# TOKEN = '435224023:AAGU8pcQMqb-zRsIbzLl3inSEq8RpRl0ZFk' # Net.hr Test Bot

class TgNewsBot
  extend TelegramHelpers

  Storage.init

  Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|
    bot.listen do |message|

      case message
      when Telegram::Bot::Types::CallbackQuery
        site_sku, category_sku, index = message.data.split('.')

        begin
          Storage.update_page(bot, message, site_sku, category_sku, index.to_i)
          bot.api.answer_callback_query(callback_query_id: message.id)
        rescue Telegram::Bot::Exceptions::ResponseError
          # occurs when user clicks inline buttons too fast
        end

      when Telegram::Bot::Types::Message
        case message.text
        when '/start', '/sites'
          welcome = "Welcome to News Feed bot made by @mpevec \n\n"
          welcome << "#{Storage.toc_text}"
          bot.api.send_message(chat_id: message.chat.id, text: welcome)

        when /^[0-9]+\.[0-9]+$/
          result = Storage.toc_map[message.text]

          if result.present?
            site_sku, category_sku = result
            Storage.send_first_section_article(bot, message, site_sku, category_sku)
          else
            bot.api.send_message(chat_id: message.chat.id, text: "Category does not exist in ToC.\n\n #{Storage.toc_text}")
          end
        else
          bot.api.send_message(chat_id: message.chat.id, text: "Unknown command.\n\n #{Storage.toc_text}")
        end
      else
        # nothing
      end
    end
  end
end
