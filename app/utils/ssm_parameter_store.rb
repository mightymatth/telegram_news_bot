require 'aws-sdk-ssm'

module SSMParameterStore
  class << self
    def import_env_variables
      client = Aws::SSM::Client.new

      namespace = ENV['AWS_STACK_NAME'] || 'tg-news-bot'
      client.get_parameters_by_path(path: "/#{namespace}/").parameters.each do |parameter|
        parameter_name = parameter.name.split('/').last
        ENV[parameter_name] = parameter.value
      end
    end
  end
end
