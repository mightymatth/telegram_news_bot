require_relative 'test_helper'

# Stub SSMParameterStore before loading lambda.rb so it doesn't call AWS
require_relative '../app/services/ssm_parameter_store'

module SSMParameterStore
  class << self
    def import_env_variables
      # no-op in tests
    end
  end
end

require_relative '../app/lambda'

class LambdaTest < Minitest::Test
  def test_handler_returns_200_for_valid_message
    event = {
      'body' => {
        'update_id' => 123,
        'message' => {
          'message_id' => 1,
          'date' => 1234567890,
          'chat' => { 'id' => 42, 'type' => 'private' },
          'from' => { 'id' => 1, 'is_bot' => false, 'first_name' => 'Test' },
          'text' => 'hello'
        }
      }.to_json
    }

    mock_api = Minitest::Mock.new
    mock_api.expect(:send_message, true, [], chat_id: 42,
      text: 'Wrong domain. Try some of these...',
      parse_mode: 'Markdown',
      reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup)

    QueryResolver.instance_variable_set(:@client, mock_api)

    TrackEvent.stub(:start, nil) do
      TrackEvent.stub(:unknown_command, nil) do
        result = handler(event: event, context: nil)
        assert_equal({ statusCode: 200 }, result)
      end
    end
    mock_api.verify
  end

  def test_handler_returns_200_for_domain_query
    event = {
      'body' => {
        'update_id' => 124,
        'message' => {
          'message_id' => 2,
          'date' => 1234567890,
          'chat' => { 'id' => 42, 'type' => 'private' },
          'from' => { 'id' => 1, 'is_bot' => false, 'first_name' => 'Test' },
          'text' => 'medium.com'
        }
      }.to_json
    }

    Cache.instance_variable_set(:@map, {})
    Cache.set('medium.com', ['https://medium.com/a1'])

    mock_api = Minitest::Mock.new
    mock_api.expect(:send_message, true, [], chat_id: 42,
      text: "[Results for 'medium.com' (1/1)](https://medium.com/a1)",
      parse_mode: 'Markdown',
      reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup)

    QueryResolver.instance_variable_set(:@client, mock_api)

    TrackEvent.stub(:start, nil) do
      result = handler(event: event, context: nil)
      assert_equal({ statusCode: 200 }, result)
    end
    mock_api.verify
  end
end
