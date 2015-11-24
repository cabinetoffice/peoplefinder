if Rails.env.production? or Rails.env.staging?
  Elasticsearch::Model.client =
    Elasticsearch::Client.new(url: Rails.configuration.elastic_search_url)
end
