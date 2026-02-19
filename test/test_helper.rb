ENV['TELEGRAM_BOT_TOKEN'] ||= 'test-token'
ENV['NEWS_API_KEY'] ||= 'test-news-api-key'
ENV['MIXPANEL_TOKEN'] ||= 'test-mixpanel-token'

require 'minitest/autorun'
require 'webmock/minitest'

$LOAD_PATH.unshift File.expand_path('../app/services', __dir__)
