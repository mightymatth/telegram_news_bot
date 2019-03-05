require 'dotenv/load'
require 'telegram/bot'
require_relative 'app/utils/query_resolver'

class TgNewsBot
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
