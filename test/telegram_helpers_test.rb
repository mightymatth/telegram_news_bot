require_relative 'test_helper'
require_relative '../app/services/telegram_helpers'

class TelegramHelpersTest < Minitest::Test
  # Include the module to test instance methods
  include TelegramHelpers

  def test_get_telegram_link
    link = get_telegram_link('https://example.com', 'abc123')
    assert_equal 'https://t.me/iv?url=https%3A%2F%2Fexample.com&rhash=abc123', link
  end

  def test_generate_header
    Cache.instance_variable_set(:@map, {})
    Cache.set('example.com', ['url1', 'url2', 'url3'])

    header = generate_header('example.com', 0)
    assert_equal "Results for 'example.com' (1/3)", header
  end

  def test_extract_message_with_regular_message
    data = {
      'update_id' => 123,
      'message' => {
        'message_id' => 1,
        'date' => 1234567890,
        'chat' => { 'id' => 42, 'type' => 'private' },
        'text' => 'hello'
      }
    }
    message = TelegramHelpers.extract_message(data)
    assert_instance_of Telegram::Bot::Types::Message, message
    assert_equal 'hello', message.text
    assert_equal 42, message.chat.id
  end

  def test_extract_message_with_callback_query
    data = {
      'update_id' => 124,
      'callback_query' => {
        'id' => '999',
        'chat_instance' => 'test',
        'from' => { 'id' => 1, 'is_bot' => false, 'first_name' => 'Test' },
        'data' => 'medium.com#0'
      }
    }
    message = TelegramHelpers.extract_message(data)
    assert_instance_of Telegram::Bot::Types::CallbackQuery, message
    assert_equal 'medium.com#0', message.data
  end

  def test_extract_message_with_inline_query
    data = {
      'update_id' => 125,
      'inline_query' => {
        'id' => '777',
        'from' => { 'id' => 1, 'is_bot' => false, 'first_name' => 'Test' },
        'query' => 'search term',
        'offset' => ''
      }
    }
    message = TelegramHelpers.extract_message(data)
    assert_instance_of Telegram::Bot::Types::InlineQuery, message
    assert_equal 'search term', message.query
  end

  def test_examples_markup_creates_inline_keyboard
    markup = examples_markup
    assert_instance_of Telegram::Bot::Types::InlineKeyboardMarkup, markup
    assert_equal 2, markup.inline_keyboard.size
    assert_equal 2, markup.inline_keyboard[0].size
    assert_equal 'medium.com', markup.inline_keyboard[0][0].text
    assert_equal 'medium.com#0', markup.inline_keyboard[0][0].callback_data
  end

  def test_next_previous_markup_first_item
    Cache.instance_variable_set(:@map, {})
    Cache.set('example.com', ['url1', 'url2', 'url3'])

    markup = next_previous_markup('example.com', 0)
    assert_instance_of Telegram::Bot::Types::InlineKeyboardMarkup, markup
    buttons = markup.inline_keyboard[0]
    assert_equal 1, buttons.size
    assert_equal 'Next »', buttons[0].text
  end

  def test_next_previous_markup_middle_item
    Cache.instance_variable_set(:@map, {})
    Cache.set('example.com', ['url1', 'url2', 'url3'])

    markup = next_previous_markup('example.com', 1)
    buttons = markup.inline_keyboard[0]
    assert_equal 2, buttons.size
    assert_equal '« Previous', buttons[0].text
    assert_equal 'Next »', buttons[1].text
  end

  def test_next_previous_markup_last_item
    Cache.instance_variable_set(:@map, {})
    Cache.set('example.com', ['url1', 'url2', 'url3'])

    markup = next_previous_markup('example.com', 2)
    buttons = markup.inline_keyboard[0]
    assert_equal 1, buttons.size
    assert_equal '« Previous', buttons[0].text
  end
end
