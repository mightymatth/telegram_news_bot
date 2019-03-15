require 'telegram/bot'
require_relative 'event_tracker'
require_relative 'telegram_helpers'

module QueryResolver
  extend TelegramHelpers

  class << self
    def process(message)
      case message
      when Telegram::Bot::Types::InlineQuery
        query = message.query.downcase
        p 'inline query', query
      when Telegram::Bot::Types::CallbackQuery
        cache_key, index = message.data.split('#')

        begin
          update_message(message, cache_key, index.to_i)
          api_client.answer_callback_query(callback_query_id: message.id)
          TrackEvent.article_change(message, cache_key, index.to_i)
        rescue Telegram::Bot::Exceptions::ResponseError
          # occurs when user clicks inline buttons too fast
        end
      when Telegram::Bot::Types::Message
        case message.text
        when '/start',
          TrackEvent.start(message)
          @welcome ||= IO.read(File.join(File.dirname(__FILE__), "../assets/files/welcome.md"))
          send_markdown_text(message.chat, @welcome)

          api_client.send_message(chat_id: message.chat.id,
                                  text: @welcome,
                                  parse_mode: 'Markdown',
                                  reply_markup: examples_markup)
        when /\A([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}\Z/ # domain
          urls = Cache.get(message.text)

          if urls.present?
            send_first_section_article(message, message.text)
          else
            send_markdown_text(message.chat,
                               "There are no available articles for this domain.\n\n")
          end
        else
          api_client.send_message(chat_id: message.chat.id,
                                  text: 'Wrong domain. Try some of these...',
                                  parse_mode: 'Markdown',
                                  reply_markup: examples_markup)
          TrackEvent.unknown_command(message)
        end
      else
        # nothing
      end
    end
  end
end
