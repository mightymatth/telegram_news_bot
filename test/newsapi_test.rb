require_relative 'test_helper'
require_relative '../app/services/newsapi'

class NewsApiTest < Minitest::Test
  def setup
    # Reset memoized client
    NewsApi.instance_variable_set(:@news_api_client, nil)
  end

  def test_client_creates_news_instance
    client = NewsApi.client
    assert_instance_of News, client
  end

  def test_client_is_memoized
    client1 = NewsApi.client
    client2 = NewsApi.client
    assert_same client1, client2
  end

  def test_news_for_domain_returns_urls
    mock_article = Minitest::Mock.new
    mock_article.expect(:url, 'https://example.com/article1')

    mock_client = Minitest::Mock.new
    mock_client.expect(:get_everything, [mock_article], [], domains: 'example.com', pageSize: 100, sortBy: 'popularity')

    NewsApi.stub(:client, mock_client) do
      urls = NewsApi.news_for_domain('example.com')
      assert_equal ['https://example.com/article1'], urls
    end

    mock_client.verify
    mock_article.verify
  end
end
