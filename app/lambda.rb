require_relative 'utils/telegram_helpers'
require_relative 'utils/query_resolver'
require 'json'

def handler(event:, context:)
  message = TelegramHelpers.extract_message(JSON.parse(event['body']))
  QueryResolver.process(message)

  { statusCode: 200 }
end
