require 'nokogiri'
require 'open-uri'
require 'concurrent'
require 'yaml'
require 'active_support/all'
require 'telegram/bot'
require_relative 'cache'

module TelegramHelpers
  def api_client
    @client ||= Telegram::Bot::Api.new(ENV['TELEGRAM_BOT_TOKEN'])
  end

  def get_telegram_link(url, rhash)
    uri = URI.parse('https://t.me/iv')
    uri.query = URI.encode_www_form({url: url, rhash: rhash})
    uri.to_s
  end

  def log_sending(subject, message_from)
    puts "[#{Time.now}] Sending '#{subject}' to #{message_from.first_name} #{message_from.last_name} (#{message_from.username})"
  end

  def send_markdown_text(chat, markdown_text)
    api_client.send_message(chat_id: chat.id,
                     text: markdown_text,
                     parse_mode: 'Markdown')
  end

  def update_message(message, cache_key, index)
    link = Cache.get_link(cache_key, index)

    if message.message&.entities&.first&.url != link
      text = generate_header(cache_key, index)

      edit_message_params = {
        text: "[#{text}](#{link})",
        parse_mode: 'Markdown',
        reply_markup: next_previous_markup(cache_key, index)
      }

      if message.message.present?
        edit_message_params[:chat_id] = message.message&.chat.id
        edit_message_params[:message_id] = message.message&.message_id
      else
        edit_message_params[:inline_message_id] = message.inline_message_id
      end

      api_client.edit_message_text(edit_message_params)
    end
  end


  def next_previous_markup(cache_key, index)
    keyboard = [[]]

    show_previous = index > 0
    show_next = index + 1 < Cache.get_size(cache_key)
    keyboard[0] << Telegram::Bot::Types::InlineKeyboardButton.new(
      text: '« Previous',
      callback_data: "#{cache_key}\##{index - 1}") if show_previous
    keyboard[0] << Telegram::Bot::Types::InlineKeyboardButton.new(
      text: 'Next »',
      callback_data: "#{cache_key}\##{index + 1}") if show_next

    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
  end

  def get_first_section_article_info(cache_key)
    text = generate_header(cache_key, 0)
    link = Cache.get_link(cache_key, 0)
    reply_markup = next_previous_markup(cache_key, 0)


    [text, link, reply_markup]
  end

  def send_first_section_article(message, cache_key)
    text, link, reply_markup = get_first_section_article_info(cache_key)
    api_client.send_message(chat_id: message.chat.id,
                            text: "[#{text}](#{link})",
                            parse_mode: 'Markdown',
                            reply_markup: reply_markup)
  end

  def generate_header(cache_key, index)
    "Results for '#{cache_key}' (#{index + 1}/#{Cache.get_size(cache_key)})"
  end

  class << self
    def extract_message(telegram_data)
      update = Telegram::Bot::Types::Update.new(telegram_data)
      types = %w(inline_query
                     chosen_inline_result
                     callback_query
                     edited_message
                     message
                     channel_post
                     edited_channel_post)
      types.inject(nil) { |acc, elem| acc || update.public_send(elem) }
    end
  end
end
