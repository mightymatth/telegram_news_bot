require_relative 'test_helper'
require_relative '../app/services/cache'

class CacheTest < Minitest::Test
  def setup
    # Reset Cache internal state between tests
    Cache.instance_variable_set(:@map, {})
  end

  def test_set_and_get_urls
    urls = ['https://example.com/1', 'https://example.com/2']
    Cache.set('example.com', urls)

    assert_equal urls, Cache.instance_variable_get(:@map)['example.com']['urls']
  end

  def test_get_fetches_from_newsapi_when_empty
    urls = ['https://example.com/article1']
    NewsApi.stub(:news_for_domain, urls) do
      result = Cache.get('example.com')
      assert_equal urls, result
    end
  end

  def test_get_returns_cached_value_when_not_expired
    urls = ['https://example.com/cached']
    Cache.set('example.com', urls)

    NewsApi.stub(:news_for_domain, ->(_) { raise 'Should not be called' }) do
      result = Cache.get('example.com')
      assert_equal urls, result
    end
  end

  def test_get_size_returns_url_count
    Cache.set('example.com', ['url1', 'url2', 'url3'])
    assert_equal 3, Cache.get_size('example.com')
  end

  def test_get_link_returns_url_at_index
    Cache.set('example.com', ['url0', 'url1', 'url2'])
    assert_equal 'url1', Cache.get_link('example.com', 1)
  end

  def test_cache_exceeded_returns_true_for_old_entry
    old_time = Time.now.utc - 600
    assert Cache.cache_exceeded(old_time)
  end

  def test_cache_exceeded_returns_false_for_fresh_entry
    recent_time = Time.now.utc - 10
    refute Cache.cache_exceeded(recent_time)
  end

  def test_cache_exceeded_respects_env_variable
    ENV['CACHE_DURATION_SECS'] = '5'
    old_time = Time.now.utc - 10
    assert Cache.cache_exceeded(old_time)
  ensure
    ENV.delete('CACHE_DURATION_SECS')
  end
end
