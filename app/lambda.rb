require_relative 'utils/ssm_parameter_store'
require_relative 'utils/telegram_helpers'
require_relative 'utils/query_resolver'
require 'json'

SSMParameterStore.import_env_variables

def handler(event:, context:)
  message = TelegramHelpers.extract_message(JSON.parse(event['body']))
  QueryResolver.process(message)

  { statusCode: 200 }
end
