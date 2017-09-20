require 'nokogiri'
require 'open-uri'
require 'concurrent'
require 'yaml'
require 'active_support/all'
require 'telegram/bot'

module TelegramHelpers
  def get_telegram_link(url, rhash)
    uri = URI.parse('https://t.me/iv')
    uri.query = URI.encode_www_form({url: url, rhash: rhash})
    uri.to_s
  end

  # def send_link_preview_message(bot, chat_id, link)
  #   html_link = "[»](#{link})"
  #   bot.api.send_message(chat_id: chat_id, text: html_link,
  #                        parse_mode: 'Markdown',
  #                        reply_markup: {hide_keyboard: true})
  # end

  def log_sending(subject, message_from)
    puts "[#{Time.now}] Sending '#{subject}' to #{message_from.first_name} #{message_from.last_name} (#{message_from.username})"
  end



  # def set_subtitle(site_sku, category_sku, index)
  #   "#{section_label.to_s.titlecase} (#{index + 1}/#{Section.get(category_sku).size})"
  # end

  def home_keyboard_markup
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: ['Most Popular', 'Most Recent', 'Croatia', 'World'],
      one_time_keyboard: true)
  end


end
