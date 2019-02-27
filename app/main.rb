require 'telegram/bot'
require 'dotenv/load'
require_relative 'utils/telegram_helpers'
require_relative 'utils/query_resolver'

class TgNewsBot
  extend TelegramHelpers

  Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|
    begin
      bot.listen do |message|
        QueryResolver.process(message)
      end
    rescue Exception
      retry
    end
  end
end
