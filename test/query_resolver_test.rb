require_relative 'test_helper'
require_relative '../app/services/query_resolver'

class QueryResolverTest < Minitest::Test
  def setup
    Cache.instance_variable_set(:@map, {})
    # Stub the API client to prevent real HTTP calls
    @mock_api = Minitest::Mock.new
    QueryResolver.instance_variable_set(:@client, @mock_api)
  end

  def test_process_handles_inline_query
    message = Telegram::Bot::Types::InlineQuery.new(
      id: '123',
      from: { id: 1, is_bot: false, first_name: 'Test' },
      query: 'SOME QUERY',
      offset: ''
    )
    # Should not raise - just prints to stdout
    assert_output(/inline query/) do
      QueryResolver.process(message)
    end
  end

  def test_process_handles_domain_message_with_results
    urls = ['https://medium.com/article1', 'https://medium.com/article2']
    Cache.set('medium.com', urls)

    message = Telegram::Bot::Types::Message.new(
      message_id: 1,
      date: 1234567890,
      chat: { id: 42, type: 'private' },
      from: { id: 1, is_bot: false, first_name: 'Test' },
      text: 'medium.com'
    )

    @mock_api.expect(:send_message, true, [], chat_id: 42,
      text: "[Results for 'medium.com' (1/2)](https://medium.com/article1)",
      parse_mode: 'Markdown',
      reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup)

    # TrackEvent.start is called during when-clause evaluation (trailing comma
    # on the '/start' line in query_resolver.rb makes it part of the condition)
    TrackEvent.stub(:start, nil) do
      QueryResolver.process(message)
    end
    @mock_api.verify
  end

  def test_process_handles_domain_with_no_results
    message = Telegram::Bot::Types::Message.new(
      message_id: 1,
      date: 1234567890,
      chat: { id: 42, type: 'private' },
      from: { id: 1, is_bot: false, first_name: 'Test' },
      text: 'nonexistent.com'
    )

    TrackEvent.stub(:start, nil) do
      NewsApi.stub(:news_for_domain, []) do
        @mock_api.expect(:send_message, true, [], chat_id: 42,
          text: "There are no available articles for this domain.\n\n",
          parse_mode: 'Markdown')

        QueryResolver.process(message)
        @mock_api.verify
      end
    end
  end

  def test_process_handles_unknown_text
    message = Telegram::Bot::Types::Message.new(
      message_id: 1,
      date: 1234567890,
      chat: { id: 42, type: 'private' },
      from: { id: 1, is_bot: false, first_name: 'Test' },
      text: 'not a domain'
    )

    @mock_api.expect(:send_message, true, [], chat_id: 42,
      text: 'Wrong domain. Try some of these...',
      parse_mode: 'Markdown',
      reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup)

    TrackEvent.stub(:start, nil) do
      TrackEvent.stub(:unknown_command, nil) do
        QueryResolver.process(message)
      end
    end
    @mock_api.verify
  end

  def test_process_ignores_unknown_message_types
    # Should not raise for nil/unhandled types
    QueryResolver.process(nil)
  end
end
