require 'telegram/bot'
require 'dotenv/load'
require_relative 'utils/event_tracker'
require_relative 'utils/telegram_helpers'
require_relative 'utils/storage'

STDOUT.sync = true

class TgNewsBot
  extend TelegramHelpers

  Storage.init
  sleep(10)

  Storage.fill_data_for_inline_queries

  Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|

    begin
      bot.listen do |message|

        case message
        when Telegram::Bot::Types::InlineQuery
          query = message.query.downcase
          results = Storage.articles_for_inline.select { |article| article.title.downcase.include?(query) }
          bot.api.answer_inline_query(inline_query_id: message.id, results: results)
        when Telegram::Bot::Types::CallbackQuery
          site_sku, category_sku, index = message.data.split('.')

          begin
            Storage.update_page(bot, message, site_sku, category_sku, index.to_i)
            bot.api.answer_callback_query(callback_query_id: message.id)
            TrackEvent.article_change(message, site_sku, category_sku, index)
          rescue Telegram::Bot::Exceptions::ResponseError
            # occurs when user clicks inline buttons too fast
          end
        when Telegram::Bot::Types::Message
          case message.text
          when '/start', '/sites'
            TrackEvent.start(message)
            @welcome ||= IO.read('app/assets/files/welcome.md')

            @welcome << "\n\n#{Storage.toc_text}"
            bot.api.send_message(chat_id: message.chat.id,
                                 text: @welcome,
                                 parse_mode: 'Markdown')

          when /^[0-9]+\.[0-9]+$/
            result = Storage.toc_map[message.text]

            if result.present?
              site_sku, category_sku = result
              Storage.send_first_section_article(bot, message, site_sku, category_sku)
              TrackEvent.category_picked(message, site_sku, category_sku)
            else
              bot.api.send_message(chat_id: message.chat.id,
                                   text: "Category does not exist in ToC.\n\n #{Storage.toc_text}",
                                   parse_mode: 'Markdown')
              TrackEvent.category_missed(message)
            end
          else
            bot.api.send_message(chat_id: message.chat.id,
                                 text: "Unknown command.\n\n #{Storage.toc_text}",
                                 parse_mode: 'Markdown')
            TrackEvent.unknown_command(message)
          end
        else
          # nothing
        end
      end
    rescue Exception
      retry
    end
  end
end
