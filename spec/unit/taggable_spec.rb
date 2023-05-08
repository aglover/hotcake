
require 'json'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/taggable')


RSpec.describe Taggable::Application do

    before(:each) do
      @factory = Taggable::TaggableFactory.new()
    end

    describe "a Taggable thing as a model" do
       
      it "can represent infrastructure" do
        tag_thing = @factory.manufactureTaggable()
        tag_thing.name = "bluespar"
        tag_thing.env = "prod"
        tag_thing.infra_type = "cluster"
        tag_thing.infra_name = "MAIN"
        
        expect(tag_thing.infra_type).to eq "cluster"
        expect(tag_thing.infra_name).to eq "MAIN"
      end

      it "can represent infrastructure items with properties" do
        tags = ["FIT", "expired", "SEV0"]
        properties = {:vul_sev => "high", :service_type => "SPS" }
        tag_thing = @factory.manufactureTaggable()
        tag_thing.tags = tags
        
        tag_thing.props = properties
        expect(tag_thing.tags.size).to eq 3
        expect(tag_thing.tags).to eq ["FIT", "expired", "SEV0"]   

        expect(tag_thing.props.size).to eq 2
        tmp_hsh = {:vul_sev => "high", :service_type => "SPS" }
        expect(tag_thing.props).to eq tmp_hsh
      end
    end

    describe "a taggable thing can be a hash" do
      it "can represent itself as a hash (i.e. for es)" do
        tag_thing = @factory.manufactureTaggable()
        tag_thing.name = "bluespar"
        tag_thing.env = "prod"
        a_hash = tag_thing.as_hash
        expect(a_hash.nil?).to be false

        expect(a_hash[:application]).to eq "bluespar"
        expect(a_hash[:environment]).to eq "prod"
      end
    end

    describe "a taggable thing can be a document too" do

      it "can represent itself as a document with optional attributes and tags and properties" do
        tag_thing = @factory.manufactureTaggable()
        tag_thing.name = "bluespar"
        tag_thing.env = "prod"
        tag_thing.infra_type = "cluster"
        tag_thing.infra_name = "MAIN"
        tag_thing.tags =  ["vul1", "deprecated"]
        tag_thing.props = {:stack => "TEST"}

        a_json_string = tag_thing.as_document
        parsed = JSON.parse(a_json_string)
        expect(parsed["application"]).to eq "bluespar"
        expect(parsed["environment"]).to eq "prod"
        expect(parsed["infra_type"]).to eq "cluster"
        expect(parsed["infra_name"]).to eq "MAIN"
        expect(parsed["properties"].size).to eq 1
        expect(parsed["properties"]["stack"]).to eq "TEST"
        expect(parsed["tags"].size).to eq 2
      end

    end
  end