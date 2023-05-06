ENV['APP_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require File.expand_path(File.dirname(__FILE__) + '/../lib/tag_app')

RSpec.describe "Simple Hello World" do
    include Rack::Test::Methods
  
    def app
      Sinatra::Application
    end
  
    it "says hello" do
      get "/"
      expect(last_response).to be_ok
      expect(last_response.body).to eq({message:"Hello world"}.to_json)
      expect(last_response.headers['Content-Type']).to eq "application/json"
    end
    
  end