require 'yaml'
require 'concurrent'
require 'nokogiri'
require_relative 'telegram_helpers'

module Storage
  extend TelegramHelpers

  @config = Concurrent::Map.new
  @config = YAML.load_file('storage_config.yml')
  @articles = Concurrent::Hash.new
  @toc_text = ''
  @toc_map = {}

  class << self
    attr_reader :articles, :config, :toc_text, :toc_map

    def set_articles(site_sku, section_sku, articles)
      @articles[site_sku] = {} unless @articles[site_sku]
      @articles[site_sku][section_sku] = articles
    end

    def get_articles(site_sku, section_sku)
      return nil unless @articles[site_sku]
      @articles[site_sku][section_sku]
    end

    def get_sections(site_sku)
      @articles[site_sku].keys
    end

    def site_name_to_sku(name)
      @config['sites'].select {|site| site['name'].eql? name}.first&.[]('sku')
    end

    def site_sku_to_name(sku)
      @config['sites'].select {|site| site['sku'].eql? sku}.first&.[]('name')
    end

    def category_name_to_sku(site_sku, name)
      @config['sites']
        .select {|site| site['sku'].eql? site_sku}
        .first&.[]('categories')
        &.select {|category| category['name'].eql? name}
        &.first&.[]('sku')
    end

    def category_sku_to_name(site_sku, sku)
      @config['sites']
        .select {|site| site['sku'].eql? site_sku}
        .first&.[]('categories')
        &.select {|category| category['sku'].eql? sku}
        &.first&.[]('name')
    end

    def get_link(site_sku, category_sku, index)
      sections = get_articles(site_sku, category_sku)
      link = sections[index]
      link = sections[0] unless link
      link
    end

    def init
      fill_toc

      @config['sites'].each do |site|
        puts "Filling site #{site['name']}"
        Concurrent::TimerTask.new(execution_interval: site['refresh_rate'], run_now: true) {
          site['categories'].each do |category|
            Concurrent::Promise.fulfill(Nokogiri::HTML(open(category['url']))).then {|page|
              puts "Filling category #{site['name']} #{category['name']}"

              links_collection = []
              category['xpath_links'].each do |xpath_link|
                links = page.xpath(xpath_link).map do |link|
                  if site['rhash'].present?
                    get_telegram_link(link.attributes['href'].value, site['rhash'])
                  else
                    link.attributes['href'].value
                  end
                end
                links_collection += links
              end
              set_articles(site['sku'], category['sku'], links_collection)
            }.execute
          end
        }.execute
      end
    end

    def fill_toc
      @config['sites'].each_with_index do |site, site_index|
        @toc_text << "#{site['name']}:\n"

        site['categories'].each_with_index do |category, category_index|
          key = "#{site_index + 1}.#{category_index + 1}"
          @toc_text << "  #{key} #{category['name']}\n"
          @toc_map[key] = [site['sku'], category['sku']]
        end
      end
    end

    def update_page(bot, message, site_sku, category_sku, index)
      link = get_link(site_sku, category_sku, index)
      if message.message.entities.first.url != link
        bot.api.edit_message_text(
          chat_id: message.message.chat.id,
          message_id: message.message.message_id,
          text: "[Subtitle](#{link})",
          parse_mode: 'Markdown',
          reply_markup: next_previous_markup(site_sku, category_sku, index))
      end
    end

    def next_previous_markup(site_sku, category_sku, index)
      keyboard = [[]]

      show_previous = index > 0
      show_next = index + 1 < Storage.articles[site_sku][category_sku].size
      keyboard[0] << Telegram::Bot::Types::InlineKeyboardButton.new(
        text: '« Previous',
        callback_data: "#{site_sku}.#{category_sku}.#{index - 1}") if show_previous
      keyboard[0] << Telegram::Bot::Types::InlineKeyboardButton.new(
        text: 'Next »',
        callback_data: "#{site_sku}.#{category_sku}.#{index + 1}") if show_next

      Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
    end

    def send_first_section_article(bot, message, site_sku, category_sku)
      link = get_link(site_sku, category_sku, 0)
      bot.api.send_message(chat_id: message.chat.id,
                           text: "[Subtitle](#{link})",
                           parse_mode: 'Markdown',
                           reply_markup: next_previous_markup(site_sku, category_sku, 0))
    end

  end
end