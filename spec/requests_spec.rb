require 'spec_helper'
describe "requests" do
  include Rack::Test::Methods
  before(:each) do
    @session = { uniqname: 'tutor' }
    env 'rack.session', @session
  end
  context "get /" do
    it "contains 'Welcome'" do
      stub_alma_get_request(url: "users/tutor?expand=none&user_id_type=all_unique&view=full")
      get "/"
      expect(last_response.body).to include("Welcome")
    end
  end
  context "get /shelf" do
    it "redirects to '/shelf/loans'" do
      get "/shelf"
      expect(last_response.status).to eq(302)
      expect(URI(last_response.headers["Location"]).path).to eq("/shelf/loans")
    end
  end
  context "get /shelf/" do
    it "redirects to '/shelf/loans'" do
      get "/shelf/"
      expect(last_response.status).to eq(302)
      expect(URI(last_response.headers["Location"]).path).to eq("/shelf/loans")
    end
  end
  context "get /shelf/loans" do
    it "contains 'Shelf'" do
      stub_alma_get_request(url: "users/tutor/loans", query: {expand: 'renewable'})
      get "/shelf/loans"
      expect(last_response.body).to include("Shelf")
    end
    it "shows inline messages and clears the session" do
      stub_alma_get_request(url: "users/tutor/loans", query: {expand: 'renewable'}, body: File.read("spec/fixtures/loans.json"))
      renew_successful = Loan::RenewSuccessfulMessage.new
      renewed_loan = instance_double(Loan, loan_id: '1332733700000521', message: Loan::RenewSuccessfulMessage.new)
      #@session[:item_messages] = [ {loan_id: '1332733700000521', loan: renewed_loan, message: renewed_loan.message}]
      @session[:items] = [renewed_loan]
      rack_test_session.env("rack.session", @session)
      get "/shelf/loans"
      expect(last_response.body).to include(renewed_loan.message.text)
      expect(last_request.session).not_to include(:items)
    end
  end
  
  context "get /shelf/past-loans" do
    it "contains 'Past Loans'" do
      get "/shelf/past-loans" 
      expect(last_response.body).to include("Past loans")
    end
  end
  context "get /shelf/document-delivery" do
    it "contains 'Document Delivery'" do
      get "/shelf/document-delivery" 
      expect(last_response.body).to include("Document delivery")
    end
  end
  context "get /requests" do
    it "redirects to '/requests/um-library'" do
      get "/requests"
      expect(last_response.status).to eq(302)
      expect(URI(last_response.headers["Location"]).path).to eq("/requests/um-library")
    end
  end
  context "get /requests/" do
    it "redirects to '/requests/um-library'" do
      get "/requests/"
      expect(last_response.status).to eq(302)
      expect(URI(last_response.headers["Location"]).path).to eq("/requests/um-library")
    end
  end
  context "get /requests/um-library" do
    it "contains 'Requests'" do
      stub_alma_get_request(url: "users/tutor/requests")
      get "/requests/um-library"
      expect(last_response.body).to include("Requests")
    end
  end
  context "get /requests/interlibrary-loan" do
    it "contains 'From Other Institutions (Interlibrary Loan)'" do
      stub_illiad_get_request(url: "Transaction/UserRequests/tutor", 
        body: File.read("spec/fixtures/illiad_requests.json"))
      get "/requests/interlibrary-loan" 
      expect(last_response.body).to include("From Other Institutions (Interlibrary Loan)")
    end
  end
  context "get /fines" do
    it "contains 'Fines'" do
      stub_alma_get_request(url: "users/tutor/fees", query: {limit: 100, offset: 0}, 
        body: File.read("spec/fixtures/jbister_fines.json"))
      get "/fines"
      expect(last_response.body).to include("Fines")
    end
  end
  context "get /contact-information" do
    it "contains 'notifications'" do
      stub_alma_get_request(url: "users/tutor?expand=none&user_id_type=all_unique&view=full")
      get "/contact-information"
      expect(last_response.body).to include("notifications")
    end
  end
  context "post /renew_all" do
    before(:each) do
      stub_alma_get_request( url: 'users/tutor/loans', body: File.read('./spec/fixtures/loans.json'), query: {expand: 'renewable', limit: 100, offset: 0} )
      stub_alma_post_request( url: 'users/tutor/loans/1332733700000521', query: {op: 'renew'} ) 
      stub_alma_post_request( url: 'users/tutor/loans/1332734190000521', query: {op: 'renew'} ) 
    end
    it "stuffs items into the session" do
      post "/renew_all" 
      expect(last_request.env['rack.session'][:items].count).to eq(2)
    end
    it "redirects to shelf/loans" do
      post "/renew_all" 
      expect(URI(last_response.headers["Location"]).path).to eq("/shelf/loans")
    end
    it "shows appropriate flash messages" do
      alma_loans = JSON.parse(File.read('./spec/fixtures/loans.json')) 
      alma_loans["item_loan"][0]["renewable"] = false
      stub_alma_get_request( url: 'users/tutor/loans', body: alma_loans.to_json, query: {expand: 'renewable', limit: 100, offset: 0} )
      stub_alma_get_request( url: 'users/tutor/loans', body: alma_loans.to_json, query: {expand: 'renewable'} )
      post "/renew_all" 
      follow_redirect!
      expect(last_response.body).to include("1 item successfully renewed")
      expect(last_response.body).to include('The following item could not be renewed:')
    end
  end
  #ToDO 
  #context "post /renew-loan" do
    #before(:each) do
      #stub_alma_get_request(url: "users/tutor/loans", query: {expand: 'renewable'})
    #end
    #it "handles good request" do
      #stub_alma_post_request(url: "users/tutor/loans/1234", query: {op: 'renew'} )
      #post "/renew-loan", {'loan_id' => '1234'}
      #expect(URI(last_response.headers["Location"]).path).to eq("/shelf/loans")
      #follow_redirect!
      #expect(last_response.body).to include("Loan Successfully Renewed")
    #end
    #it "handles bad request" do
      #stub_alma_post_request(url: "users/tutor/loans/1234", query: {op: 'renew'}, status: 500 )
      #post "/renew-loan", {'loan_id' => '1234'}
      #expect(URI(last_response.headers["Location"]).path).to eq("/shelf/loans")
      #follow_redirect!
      #expect(last_response.body).to include("Error")
    #end
  #end
  context "post /sms" do
    before(:each) do
      @patron_json = File.read("./spec/fixtures/mrio_user_alma.json")
      stub_alma_get_request(url: "users/tutor?expand=none&user_id_type=all_unique&view=full", body: @patron_json)
    end
    it "handles good phone number update" do
      phone_number = '(734) 555-5555'
      new_phone_patron = JSON.parse(@patron_json)
      new_phone_patron["contact_info"]["phone"][1]["phone_number"] = phone_number

      stub_alma_put_request(url: "users/mrio", input: new_phone_patron.to_json, output: new_phone_patron.to_json)

      post "/sms", {'phone-number' => phone_number}
      follow_redirect!
      expect(last_response.body).to include("SMS Successfully Updated")
    end
    it "handles bad phone number update" do

      post "/sms", {'phone-number' => 'aaa'}
      follow_redirect!
      expect(last_response.body).to include("is invalid")
    end
    it "handles phone number removal" do
      new_phone_patron = JSON.parse(@patron_json)
      new_phone_patron["contact_info"]["phone"].delete_at(1)
      stub_alma_put_request(url: "users/mrio", input: new_phone_patron.to_json, output: new_phone_patron.to_json)
      post "/sms", {'phone-number' => ''}
      follow_redirect!
      expect(last_response.body).to include("SMS Successfully Removed")
    end
  end
  context "post /fines/pay" do
    it "puts fine information in session and redirects to nelnet with amountDue" do
      stub_alma_get_request( url: 'users/tutor/fees', body: File.read("./spec/fixtures/jbister_fines.json"), query: {limit: 100, offset: 0}  )
      post "/fines/pay", {'fines' => {"0" => '690390050000521'}}
      query = Addressable::URI.parse(last_response.location).query_values
      expect(last_request.env['rack.session'].key?(query["orderNumber"])).to eq(true)
      expect(query["amountDue"]).to eq("277")
    end
  end
  context "post /fines/receipt" do
    before(:each) do
      @params = {
        "transactionType"=>"1", 
        "transactionStatus"=>"1", 
        "transactionId"=>"382481568",
        "transactionTotalAmount"=>"2250",
        "transactionDate"=>"202001211341",
        "transactionAcountType"=>"VISA",
        "transactionResultCode"=>"267849",
        "transactionResultMessage"=>"Approved and completed",
        "orderNumber"=>"Afam.1608566536797",
        "orderType"=>"UMLibraryCirc",
        "orderDescription"=>"U-M Library Circulation Fines",
        "payerFullName"=>"Aardvark Jones",
        "actualPayerFullName"=>"Aardvark Jones",
        "accountHolderName"=>"Aardvark Jones",
        "streetOne"=>"555 S STATE ST",
        "streetTwo"=>"",
        "city"=>"Ann Arbor",
        "state"=>"MI",
        "zip"=>"48105",
        "country"=>"UNITED STATES",
        "email"=>"aardvark@umich.edu",
        "timestamp"=>"1579628471900",
        "hash"=>"9baaee6c2a0ee08c63bbbcc0435360b0d5ecef1de876b68d59956c0752fed836"
      }
      @item = {
        "id"=>"1384289260006381",
        "balance"=>"5.00",
        "title"=>"Short history of Georgia.",
        "barcode"=>"95677",
        "library"=>"Main Library",
        "type"=>"Overdue fine",
        "creation_time"=>"2020-12-09T17:13:29.959Z"
      }
    end
    it "for valid params, retrieves items from session, updates Alma, sets success flash, prints receipt" do
      with_modified_env NELNET_SECRET_KEY: 'secret', JWT_SECRET: 'secret' do
        stub_alma_post_request( url: 'users/tutor/fees/1384289260006381', query: {op: "pay", method: 'ONLINE', amount: '5.00'}  )
        token = JWT.encode [@item], ENV.fetch('JWT_SECRET'), 'HS256'

        env 'rack.session', 'Afam.1608566536797' => token, uniqname: 'tutor'
        get "/fines/receipt", @params 
        expect(last_response.body).to include("Fines successfully paid")
      end
    end
    it "for invalid params,  sets fail flash" do
      with_modified_env NELNET_SECRET_KEY: 'incorect_secret', JWT_SECRET: 'secret' do

        get "/fines/receipt", @params 
        expect(last_response.body).to include("Could not Validate")
      end
    end
    def with_modified_env(options, &block)
      ClimateControl.modify(options, &block)
    end
  end
end
