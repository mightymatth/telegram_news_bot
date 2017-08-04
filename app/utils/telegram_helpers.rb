require 'nokogiri'
require 'open-uri'
require 'concurrent'
require_relative 'sections'

module TelegramHelpers
  def get_telegram_link(url, rhash)
    uri = URI.parse('https://t.me/iv')
    uri.query = URI.encode_www_form({url: url, rhash: rhash})
    uri.to_s
  end

  def send_link_preview_message(bot, chat_id, link)
    html_link = "[»](#{link})"
    bot.api.send_message(chat_id: chat_id, text: html_link,
                         parse_mode: 'Markdown',
                         reply_markup: {hide_keyboard: true})
  end

  def get_link(section_label, index)
    sections = Section.get(section_label)
    link = sections[index]
    link = sections[0] unless link
    link
  end

  def update_sections
    update_most_popular_and_newest
    update_croatia
    update_world
  end

  def set_update_timer(update_interval)
    Concurrent::TimerTask.new(execution_interval: update_interval) {update_sections}.execute
  end

  def log_sending(subject, message_from)
    puts "[#{Time.now}] Sending '#{subject}' to #{message_from.first_name} #{message_from.last_name} (#{message_from.username})"
  end

  def update_page(bot, message, section_label, index)
    link = get_link(section_label, index)
    if message.message.entities.first.url != link
      bot.api.edit_message_text(
        chat_id: message.message.chat.id,
        message_id: message.message.message_id,
        text: "[#{set_subtitle(section_label, index)}](#{link})",
        parse_mode: 'Markdown',
        reply_markup: next_previous_markup(section_label, index))
    end
  end

  def next_previous_markup(section_label, index)
    keyboard = [[]]
    keyboard[0] << Telegram::Bot::Types::InlineKeyboardButton.new(
      text: '« Previous |',
      callback_data: "#{section_label}.#{index - 1}") if index > 0
    keyboard[0] << Telegram::Bot::Types::InlineKeyboardButton.new(
      text: '| Next »',
      callback_data: "#{section_label}.#{index + 1}") if Section.get(section_label)[index + 1]

    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
  end

  def send_first_section_article(bot, message, section_label)
    link = get_link(section_label, 0)
    bot.api.send_message(chat_id: message.chat.id,
                         text: "[#{set_subtitle(section_label, 0)}](#{link})",
                         parse_mode: 'Markdown',
                         reply_markup: next_previous_markup(section_label, 0))
  end

  def set_subtitle(section_label, index)
    "#{section_label} (#{index + 1}/#{Section.get(section_label).size})"
  end

  private

  def update_most_popular_and_newest
    Concurrent::Promise.fulfill(Nokogiri::HTML(open('http://www.net.hr'))).then {|page|
      puts "[#{Time.now}] Fetched #{page.title}"
      most_popular = page.css('div.tab_1 a').map {|link| get_telegram_link(link.values[0], RHASH)}
      newest = page.css('div.tab_2 a').map {|link| get_telegram_link(link.values[0], RHASH)}
      Section.set(:most_popular, most_popular)
      Section.set(:newest, newest)
    }.execute
  end

  def update_croatia
    Concurrent::Promise.fulfill(Nokogiri::HTML(open('http://net.hr/kategorija/danas/hrvatska/'))).then {|page|
      puts "[#{Time.now}] Fetched #{page.title}"
      croatia = page.css('section.feed.cf article.article-feed').map {|article|
        get_telegram_link(article.css('div.article-text a')[0].values[0], RHASH)
      }
      Section.set(:croatia, croatia)
    }.execute
  end

  def update_world
    Concurrent::Promise.fulfill(Nokogiri::HTML(open('http://net.hr/kategorija/danas/svijet/'))).then {|page|
      puts "[#{Time.now}] Fetched #{page.title}"
      world = page.css('section.feed.cf article.article-feed').map {|article|
        get_telegram_link(article.css('div.article-text a')[0].values[0], RHASH)
      }
      Section.set(:world, world)
    }.execute
  end
end
