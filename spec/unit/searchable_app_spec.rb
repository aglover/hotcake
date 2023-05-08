require File.expand_path(File.dirname(__FILE__) + '/../../lib/taggable')


RSpec.describe Taggable::SearchableApplication do

    before(:each) do
        @factory = Taggable::TaggableFactory.new()
    end

    describe "saving an application should be easy" do
        it "can save a model easily" do
            tag_thing = @factory.manufactureTaggable()

            mock_client = spy("Elasticsearch::Client")
            allow(mock_client).to receive(:index).and_return({_id: "blah"})

            tag_thing.es_client = mock_client

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
            tag_thing = @factory.manufactureTaggable()

            expect {
                tag_thing.save
            }.to raise_error("invalid SearchableApplication -- there must be an application name")

        end
    end

    describe "deleting should be straightforward" do
        it "should NOT delete by if no valid properties were provided (name and env)" do
            tag_thing = @factory.manufactureTaggable()

            mock_client = spy("Elasticsearch::Client")
            allow(mock_client).to receive(:delete) #.and_return({_id: "blah"})
            tag_thing.es_client = mock_client

            tag_thing.name = "bluespar"
             expect{
                tag_thing.delete
            }.to raise_error("cannot delete w/o name and env")
        end

        it "should delete by id" do
            tag_thing = @factory.manufactureTaggable()

            mock_client = spy("Elasticsearch::Client")
            allow(mock_client).to receive(:delete) #.and_return({_id: "blah"})
            tag_thing.es_client = mock_client

            tag_thing.name = "bluespar"
            tag_thing.env = "prod"

            tag_thing.delete
            # expect(mock_client).to have_received(:delete)
        end
    end

    describe "finding documents should return taggable objects" do
        it "should support find a taggable via it's name and env" do
            tag_thing = @factory.manufactureTaggable()

            mock_client = spy("Elasticsearch::Client")
            allow(mock_client).to receive(:search) #.and_return({_id: "blah"})
            tag_thing.es_client = mock_client

            result = tag_thing.find_by_name_and_env "bluespar", "test"

            # expect(result.name).to eq "bluespar" 

        end
    end

end