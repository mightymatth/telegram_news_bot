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
  @articles_for_inline = []

  class << self
    attr_reader :articles, :config, :toc_text, :toc_map, :articles_for_inline

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
      link = sections&.[](index)
      link = sections&.[](0) unless link
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
      @toc_text << "*Table of Contents*\n"
      @config['sites'].each_with_index do |site, site_index|
        @toc_text << "*#{site['name']}*:\n"

        site['categories'].each_with_index do |category, category_index|
          key = "#{site_index + 1}.#{category_index + 1}"
          @toc_text << "  `#{key}` _#{category['name']}_\n"
          @toc_map[key] = [site['sku'], category['sku']]
        end
      end
    end

    def update_page(bot, message, site_sku, category_sku, index)
      link = get_link(site_sku, category_sku, index)
      if message.message&.entities&.first&.url != link
        text = generate_header(site_sku, category_sku, index)

        edit_message_params = {
          text: "[#{text}](#{link})",
          parse_mode: 'Markdown',
          reply_markup: next_previous_markup(site_sku, category_sku, index)
        }

        if message.message.present?
          edit_message_params[:chat_id] = message.message&.chat.id
          edit_message_params[:message_id] = message.message&.message_id
        else
          edit_message_params[:inline_message_id] = message.inline_message_id
        end

        bot.api.edit_message_text(edit_message_params)
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

    def get_first_section_article_info(site_sku, category_sku)
      text = generate_header(site_sku, category_sku, 0)
      link = get_link(site_sku, category_sku, 0)
      reply_markup = next_previous_markup(site_sku, category_sku, 0)

      [text, link, reply_markup]
    end

    def send_first_section_article(bot, message, site_sku, category_sku)
      text, link, reply_markup = get_first_section_article_info(site_sku, category_sku)
      bot.api.send_message(chat_id: message.chat.id,
                           text: "[#{text}](#{link})",
                           parse_mode: 'Markdown',
                           reply_markup: reply_markup)
    end

    def generate_header(site_sku, category_sku, index)
      site_name = site_sku_to_name(site_sku)
      category_name = category_sku_to_name(site_sku, category_sku)
      category_size = Storage.articles[site_sku][category_sku].size

      "#{site_name}: #{category_name} (#{index + 1}/#{category_size})"
    end

    def fill_data_for_inline_queries
      index = 1
      @config['sites'].each do |site|
        site['categories'].each do |category|
          site_name = site_sku_to_name(site['sku'])
          category_name = category_sku_to_name(site['sku'], category['sku'])

          text, link, reply_markup = get_first_section_article_info(site['sku'], category['sku'])

          @articles_for_inline << Telegram::Bot::Types::InlineQueryResultArticle.new(
            id: index,
            title: "#{site_name} #{category_name}",
            thumb_url: site['logo_url'],
            input_message_content: Telegram::Bot::Types::InputTextMessageContent.new(
              message_text: "[#{text}](#{link})",
              parse_mode: 'Markdown'
            ),
            reply_markup: reply_markup
          )
          index += 1
        end
      end
    end

  end
end