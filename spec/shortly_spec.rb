# add files to load path
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "../"))
require 'shortly'
require 'rack/test'

set :environment, :test

configure :test do
    ActiveRecord::Base.establish_connection(
       :adapter =>  'sqlite3',
       :database => 'db/test.sqlite3.db'
     )
end

describe "URL Shortener" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  context "successful requests" do
    it "can shorten a link" do
      post '/links', {:url => 'http://www.nytimes.com'}.to_json
      last_response.status == 200
      last_response.body.should_not be_empty
    end

    it "fetches the page title" do
      post '/links', {:url => 'http://www.nytimes.com'}.to_json
      Link.last.title.should_not be_empty
    end

    context "for the same link" do
      before do
        @url = 'http://www.google.com'
        post '/links', {:url => @url}.to_json
        last_response.body.should_not be_empty
        @short_link = last_response.body
      end

      it "returns the same short-url" do
        5.times do
          post '/links', {:url => @url}.to_json
          last_response.body.should == @short_link
        end
      end

      it "does not create extra database entries" do
        expect {
          5.times do
            post '/links', {:url => @url}.to_json
          end
        }.to_not change{ Link.count }
      end
    end

    context "using short-urls" do
      before do
        post '/links', {:url => 'http://www.hackreactor.com'}.to_json
        @short_code = JSON.parse(last_response.body)['code']
      end

      it "redirects correctly" do
        get '/' + @short_code
        last_response.should be_redirect
        follow_redirect!
        last_request.url.should == 'http://www.hackreactor.com/'
      end

      it "increments the visit count" do
        expect {
          get '/' + @short_code
          last_response.should be_redirect
          follow_redirect!
        }.to change{ Link.last.visits }
      end

      it "logs date and time" do
        expect {
          get '/' + @short_code
          last_response.should be_redirect
          follow_redirect!
        }.to change{ Click.count }
      end
    end

  end

  context "unsuccessful requests" do
    it "returns a 404 for a nonsense short-link" do
      get "/notacorrectlink"
      last_response.status.should == 404
    end

    it "does not accepts non-absolute urls" do
      post '/links', {:url => 'www.hackreactor.com'}.to_json
      last_response.status.should == 404
    end
  end
end
