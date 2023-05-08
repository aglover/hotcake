require File.expand_path(File.dirname(__FILE__) + '/../lib/taggable')


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
        it "should delete by id" do
            tag_thing = @factory.manufactureTaggable()

            mock_client = spy("Elasticsearch::Client")
            allow(mock_client).to receive(:delete) #.and_return({_id: "blah"})
            tag_thing.es_client = mock_client

            tag_thing.name = "bluespar"
            tag_thing.env = "prod"

            doc_id = tag_thing.delete

            expect(mock_client).to have_received(:delete)

            # expect(doc_id).to eq "blah"de
        end
    end

end