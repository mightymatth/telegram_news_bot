require_relative 'services/ssm_parameter_store'
require_relative 'services/telegram_helpers'
require_relative 'services/query_resolver'
require 'json'

SSMParameterStore.import_env_variables

def handler(event:, context:)
  message = TelegramHelpers.extract_message(JSON.parse(event['body']))
  QueryResolver.process(message)

  { statusCode: 200 }
end
