require 'telegram/bot'
require 'dotenv/load'
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

          p 'in callback query'
          update_message(message, cache_key, index.to_i)
          p 'after update message'
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
        when /\A([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}\Z/ # domain
          urls = Cache.get(message.text)

          if urls.present?
            send_first_section_article(message, message.text)
          else
            send_markdown_text(message.chat,
                               "There are no available articles for this domain.\n\n")
          end
        else
          send_markdown_text(message.chat, "Wrong domain.\n\n")
          TrackEvent.unknown_command(message)
        end
      else
        # nothing
        p 'Did not catch message type', message
      end
    end
  end
end