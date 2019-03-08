require 'aws-sdk-ssm'

module SSMParameterStore
  class << self
    def import_env_variables
      client = Aws::SSM::Client.new

      client.get_parameters_by_path(path: '/telegramNewsBot/').parameters.each do |parameter|
        parameter_name = parameter.name.split('/').last
        ENV[parameter_name] = parameter.value
      end
    end
  end
end

