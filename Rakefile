require 'dotenv'
require 'aws-sdk-ssm'
require 'active_support/all'

desc "Reimport environment variables from .env file to SSM Parameter store."

task :reimport_params do
  unless ENV['NAMESPACE'].present?
    puts 'Variable $NAMESPACE is mandatory. Please provide namespace name that matches $AWS_STACK_NAME ' +
        'of your application (e.g. \'telegram-news-bot\').'
    exit 2
  end

  vars = Dotenv.parse('.env')
  namespace = ENV['NAMESPACE']
  client = Aws::SSM::Client.new

  puts "Deleting old parameters for NAMESPACE=#{namespace}..."
  client.get_parameters_by_path(path: "/#{namespace}/").parameters.each do |parameter|
    client.delete_parameter(name: parameter.name)
    puts "Deleted #{parameter.name}"
  end

  puts "Adding new parameters...\n"
  vars.each do |key, value|
    name = "/#{namespace}/#{key}"
    client.put_parameter(name: name, value: value, type: 'String')
    puts "Added Parameter { name: '#{name}', value: '#{value}' }"
  end

  puts 'Done!'
end
