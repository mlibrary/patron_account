class InterlibraryLoanRequests
  def initialize(parsed_response:)
    @parsed_response = parsed_response
    @requests = parsed_response.filter_map { |request| InterlibraryLoanRequest.new(request) if request["ProcessType"] != "DocDel" && request["TransactionStatus"] != "Request Finished" }
  end

  def count
    @requests.length
  end

  def each(&block)
    @requests.each do |request|
      block.call(request)
    end
  end

  def self.for(uniqname:, client: ILLiadClient.new)
    url = "/Transaction/UserRequests/#{uniqname}" 
    response = client.get(url)
    if response.code == 200
      InterlibraryLoanRequests.new(parsed_response: response.parsed_response)
    else
      #Error!
    end
  end
end

class InterlibraryLoanRequest
  def initialize(parsed_response)
    @parsed_response = parsed_response
  end
  def title
    extra = 120 - @parsed_response["LoanAuthor"].length
    extra = 0 if extra < 0
    max_length = 120 + extra
    @parsed_response["LoanTitle"][0, max_length]
  end
  def author
    extra = 120 - @parsed_response["LoanTitle"].length
    extra = 0 if extra < 0
    max_length = 120 + extra
    @parsed_response["LoanAuthor"][0, max_length]
  end
  def request_url
    "https://ill.lib.umich.edu/illiad/illiad.dll?Action=10&Form=72&Value=#{@parsed_response["TransactionNumber"]}"
  end
  def request_date
    DateTime.patron_format(@parsed_response["CreationDate"])
  end
  def expiration_date
    DateTime.patron_format(@parsed_response["DueDate"])
  end
end