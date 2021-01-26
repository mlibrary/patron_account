require 'httparty'

class ILLiadClient
  include HTTParty
  base_uri "#{ENV.fetch('ILLIAD_API_HOST')}/webplatform"

  def initialize()
    self.class.headers 'ApiKey' => ENV.fetch('ILLIAD_API_KEY')
    self.class.headers 'Accept' => 'application/json'
  end

  def get(url, query={})
    self.class.get(url, query: query)
  end

  def get_all(url:, record_key:, limit: 100, query: {})
    query[:offset] = 0 
    query[:limit] = limit
    output = get(url, query)
    if output.code == 200
      body = output.parsed_response
      while  body['total_record_count'] > limit + query[:offset]
        query[:offset] = query[:offset] + limit
        my_output = get(url, query) 
        if my_output.code == 200
          my_output.parsed_response[record_key].each {|x| body[record_key].push(x)}
        else
          return my_output #return error
        end
      end 
      ::Response.new(parsed_response: body) #return good response
    else
      output #return error
    end
  end 
end
