require 'mixpanel-ruby'
require_relative 'cache'

module TrackEvent
  @mixpanel = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])

  class << self
    def start(message)
      data = {
        '$first_name': message.from.first_name,
        '$last_name': message.from.last_name,
      }
      @mixpanel.people.set(message.from.id, data, 0)
      @mixpanel.track(message.from.id, 'start', base(message))
    end

    def category_missed(message)
      data = { text: message.text }
      @mixpanel.track(message.from.id, 'category_missed', base(message).merge(data))
    end

    def unknown_command(message)
      data = { text: message.text }
      @mixpanel.track(message.from.id, 'unknown_command', base(message).merge(data))
    end

    def article_change(message, cache_key, index)
      data = { article_url: Cache.get_link(cache_key, index) }
      @mixpanel.track(message.from.id, 'article_change', base(message).merge(data))
    end

    # Basic data for all events
    def base(message)
      {
        first_name: message.from.first_name,
        last_name: message.from.last_name,
        username: message.from.username
      }
    end
  end
end