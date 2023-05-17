ENV['APP_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require 'json'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/tag_app')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/taggable')

RSpec.describe "Tag Application" do
    include Rack::Test::Methods
  
    def app
      Sinatra::Application
    end
  

    before(:each) do
      factory = Taggable::TaggableFactory.new()
      tag_thing = factory.taggableInstance()
      tag_thing.name = "bluespar"
      tag_thing.env = "prod"
      tag_thing.infra_type = "cluster"
      tag_thing.infra_name = "MAIN"
      tag_thing.tags =  ["vul1", "deprecated"]
      tag_thing.props = {:stack => "TEST"}
      doc_id = tag_thing.save
      sleep 1
    end

    after(:each) do
      factory = Taggable::TaggableFactory.new()
      tag_thing = factory.taggableInstance()
      tag_thing.name = "bluespar"
      tag_thing.env = "prod"
      tag_thing.delete
    end

    it "responds with an application document from a specific environment" do
      get "/applications/prod/bluespar"
      expect(last_response).to be_ok
      expect(last_response.headers['Content-Type']).to eq "application/json"
      hash = JSON.parse(JSON.parse (last_response.body))
      expect(hash['application']).to eq "bluespar"
      expect(hash['infra_type']).to eq "cluster"
    end

    it "responds with application docs matching tags" do
      get "/applications?tags=deprecated"
      expect(last_response).to be_ok
      expect(last_response.headers['Content-Type']).to eq "application/json"
      array_res = JSON.parse(JSON.parse (last_response.body))
      expect(array_res.size).to eq 1
      json_res = JSON.parse(array_res[0])
      expect(json_res['application']).to eq "bluespar"
      expect(json_res['infra_type']).to eq "cluster"
    end

    it "responds with application docs matching properties" do
      get "/applications?stack=test"
      expect(last_response).to be_ok
      expect(last_response.headers['Content-Type']).to eq "application/json"
      array_res = JSON.parse(JSON.parse (last_response.body))
      expect(array_res.size).to eq 1
      json_res = JSON.parse(array_res[0])
      expect(json_res['application']).to eq "bluespar"
      expect(json_res['infra_type']).to eq "cluster"
    end

    it "responds 404 for routes not defined" do
      get "/applications/prod"
      expect(last_response.status).to eq 404
    end

    it "responds 404 for all apps as it's not defined" do
      get "/applications"
      expect(last_response.status).to eq 404
    end
    
  end