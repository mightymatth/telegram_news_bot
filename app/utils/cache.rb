require 'yaml'
require 'concurrent'
require 'nokogiri'
require_relative 'newsapi'

module Cache
  @map = Concurrent::Hash.new

  class << self
    def get(cache_key)
      if @map[cache_key].nil? || cache_exceeded(@map[cache_key]['fetched_at'])
        set(cache_key, NewsApi.news_for_domain(cache_key))
      else
        @map[cache_key]['urls']
      end
    end

    def set(cache_key, content)
      @map[cache_key] = {} if @map[cache_key].nil?
      @map[cache_key]['fetched_at'] = Time.now.utc
      @map[cache_key]['urls'] = content
    end

    def get_size(cache_key)
      get(cache_key)
      @map[cache_key]['urls'].size
    end

    def get_link(cache_key, index)
      get(cache_key)
      @map[cache_key]['urls'][index]
    end

    def cache_exceeded(time_utc)
      time_offset_sec = (ENV['CACHE_DURATION_SECS'] || 300).to_i
      Time.now.utc - time_utc > time_offset_sec
    end
  end
end
