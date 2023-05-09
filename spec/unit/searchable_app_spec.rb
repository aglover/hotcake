require File.expand_path(File.dirname(__FILE__) + '/../../lib/taggable')


RSpec.describe Taggable::SearchableApplication do

    describe "saving an application should be easy" do
        it "can save a model easily" do

            mock_client = spy("Elasticsearch::Client")
            allow(mock_client).to receive(:index).and_return({'_id' => "blah"})

            factory = Taggable::TaggableFactory.new()
            factory.es_client = mock_client

            tag_thing = factory.taggableInstance()
            tag_thing.name = "bluespar"
            tag_thing.env = "prod"
            tag_thing.infra_type = "cluster"
            tag_thing.infra_name = "MAIN"
            tag_thing.tags =  ["vul1", "deprecated"]
            tag_thing.props = {:stack => "TEST"}

            doc_id = tag_thing.save

            expect(mock_client).to have_received(:index)

            expect(doc_id).to eq "blah"
        end

        it "save should validate properties" do
            factory = Taggable::TaggableFactory.new()
            tag_thing = factory.taggableInstance()

            expect {
                tag_thing.save
            }.to raise_error("invalid SearchableApplication -- there must be an application name")

        end
    end

    describe "deleting should be straightforward" do
        it "should NOT delete by if no valid properties were provided (name and env)" do
            mock_client = spy("Elasticsearch::Client")
            allow(mock_client).to receive(:delete) 
            factory = Taggable::TaggableFactory.new()
            factory.es_client = mock_client
            tag_thing = factory.taggableInstance()

            tag_thing.name = "bluespar"
             expect{
                tag_thing.delete
            }.to raise_error("cannot delete w/o name and env")
        end

        it "should delete by id" do
            mock_client = spy("Elasticsearch::Client")
            allow(mock_client).to receive(:delete)
            factory = Taggable::TaggableFactory.new()
            factory.es_client = mock_client
            tag_thing = factory.taggableInstance()

            tag_thing.name = "bluespar"
            tag_thing.env = "prod"

            tag_thing.delete
            expect(mock_client).to have_received(:delete)
            expect(mock_client).to have_received(:search)
        end
    end

    describe "finding documents should return taggable objects" do
        it "should support find a taggable via it's name and env" do
            mock_client = spy("Elasticsearch::Client")
            allow(mock_client).to receive(:search).and_return(
                {
                    "hits" => {
                        "hits" => [
                            {   
                                "_id" => "a_test_id", 
                                "_source" =>
                                {
                                    "application"=>"bluespar", 
                                    "environment"=>"test", 
                                    "infra_type"=>"cluster", 
                                    "infra_name"=>"MAIN-B"
                                }
                            }
                        ]
                    }
                }
            )
            factory = Taggable::TaggableFactory.new()
            factory.es_client = mock_client
            tag_thing = factory.taggableInstance()
            result = Taggable::SearchableApplication.find_by_name_and_env "bluespar", "test"
            expect(result.name).to eq "bluespar" 
            expect(result.es_doc_id).to eq "a_test_id"
        end

        it "should find all documents that match a tag" do
            mock_client = spy("Elasticsearch::Client")
            allow(mock_client).to receive(:search).and_return(
                {
                    "hits" => {
                        "hits" => [
                            {   
                                "_id" => "a_test_id", 
                                "_source" =>
                                {
                                    "application"=>"bluespar", 
                                    "environment"=>"test", 
                                    "infra_type"=>"cluster", 
                                    "infra_name"=>"MAIN-B",
                                    "tags" => ["FIT", "SEC-2100"]
                                }
                            },
                            {   
                                "_id" => "a_test_id_2", 
                                "_source" =>
                                {
                                    "application"=>"spinnaker", 
                                    "environment"=>"test", 
                                    "infra_type"=>"cluster", 
                                    "infra_name"=>"SEG-MAIN",
                                    "tags" => ["FIT", "no owner"]
                                }
                            }
                        ]
                    }
                }
            )

            factory = Taggable::TaggableFactory.new()
            factory.es_client = mock_client
            tag_thing = factory.taggableInstance()
            results = Taggable::SearchableApplication.find_by_tags ["FIT"]
            expect(results.size).to eq 2
            results.each { |a_tag|
                expect(a_tag.env).to eq "test"
                expect(a_tag.infra_type).to eq "cluster"
                expect(a_tag.tags.size).to eq 2
            }
        end

        it "should find all documents that match a property or many" do
            mock_client = spy("Elasticsearch::Client")
            allow(mock_client).to receive(:search).and_return(
                {
                    "hits" => {
                        "hits" => [
                            {   
                                "_id" => "a_test_id", 
                                "_source" =>
                                {
                                    "application"=>"bluespar", 
                                    "environment"=>"test", 
                                    "infra_type"=>"cluster", 
                                    "infra_name"=>"MAIN-B",
                                    "tags" => ["FIT", "SEC-2100", "unknown"],
                                    "properties" => {
                                        "stack" => "test",
                                        "owner" => "GPS"
                                    }
                                }
                            }
                        ]
                    }
                }
            )

            factory = Taggable::TaggableFactory.new()
            factory.es_client = mock_client
            tag_thing = factory.taggableInstance()
            results = Taggable::SearchableApplication.find_by_properties({"owner" => "GPS"})
            expect(results.size).to eq 1
        end

    end
end