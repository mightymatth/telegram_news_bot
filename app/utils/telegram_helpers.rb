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

  def log_sending(subject, message_from)
    puts "[#{Time.now}] Sending '#{subject}' to #{message_from.first_name} #{message_from.last_name} (#{message_from.username})"
  end
end
