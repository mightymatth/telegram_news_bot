require 'news-api'

module NewsApi
  class << self
    def client
      @news_api_client ||= News.new(ENV['NEWS_API_KEY'])
    end

    def news_for_domain(domain)
      client
        .get_everything(domains: domain, pageSize: 100, sortBy: 'popularity')
        .map { |result| result.url}
    end
  end
end
