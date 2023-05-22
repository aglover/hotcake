ENV['APP_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require 'json'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/tag_app')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/taggable')

RSpec.describe "Tag Sinatra Application" do
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
      tuples = [{name: "bluespar", env: "prod"}, {name: "flapjack", env: "int"}]
      tuples.each do  |hash|
        begin
          factory = Taggable::TaggableFactory.new()
          tag_thing = factory.taggableInstance()
          tag_thing.name = hash[:name]
          tag_thing.env = hash[:env]
          tag_thing.delete
        rescue Exception 
          # ignore
        end
      end
    end

    describe "POST requests" do

      it "should support adding a tag to a cluster for a new application" do
        post_tags = {"tags" => ["vul", "fit"] }
        post "/applications/int/flapjack/cluster/MAIN", post_tags.to_json
        
        expect(last_response).to be_ok
        expect(last_response.headers["Content-Type"]).to eq "application/json"
        hash = JSON.parse(JSON.parse (last_response.body))
        expect(hash['tags'].size).to eq 2
        expect(hash['environment']).to eq "int"
      end

      it "should support adding properties to a cluster for a new application" do
        post_properties = {"properties" => {"email" => "dl@acme.com" } }
        post "/applications/int/flapjack/cluster/MAIN", post_properties.to_json
        
        expect(last_response).to be_ok
        expect(last_response.headers["Content-Type"]).to eq "application/json"
        hash = JSON.parse(JSON.parse (last_response.body))
        expect(hash['properties'].size).to eq 1
        expect(hash['properties']['email']).to eq "dl@acme.com"
      end

      it "should support adding a tag to a cluster for an existing application" do
        post_tags = {"tags" => ["third_tag"] }
        post "/applications/prod/bluespar/cluster/MAIN", post_tags.to_json
        
        expect(last_response).to be_ok
        expect(last_response.headers['Content-Type']).to eq "application/json"
        hash = JSON.parse(JSON.parse (last_response.body))
        expect(hash['tags'].size).to eq 3
      end

      it "should support adding a property to a cluster for an existing application" do
        post_properties = {"properties" => {"fit_purpose" => "int_testing"} }
        post "/applications/prod/bluespar/cluster/MAIN", post_properties.to_json
        
        expect(last_response).to be_ok
        expect(last_response.headers['Content-Type']).to eq "application/json"
        hash = JSON.parse(JSON.parse (last_response.body))
        expect(hash['properties'].size).to eq 2
      end

      it "should support adding a property and a tag to a cluster for an existing application" do
        post_data = {"properties" => {"service_name" => "spinnaker"}, "tags" => ["third_tag"] } 
        post "/applications/prod/bluespar/cluster/MAIN", post_data.to_json
        
        expect(last_response).to be_ok
        expect(last_response.headers['Content-Type']).to eq "application/json"
        hash = JSON.parse(JSON.parse (last_response.body))
        expect(hash['properties'].size).to eq 2
        expect(hash['tags'].size).to eq 3
      end

      it "should support deduplicating tags" do
        post_tags = {"tags" => ['deprecated'] }
        post "/applications/prod/bluespar/cluster/MAIN", post_tags.to_json
        
        expect(last_response).to be_ok
        expect(last_response.headers['Content-Type']).to eq "application/json"
        hash = JSON.parse(JSON.parse (last_response.body))
        expect(hash['tags'].size).to eq 2
      end
    end

    describe "GET requests" do
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

    describe "DELETE requests" do
      it "should support deleting by name and environment" do
        delete "/applications/prod/bluespar"
        expect(last_response).to be_ok
        expect(last_response.headers['Content-Type']).to eq "application/json"
      end
    end
  end