require 'json'
require 'elasticsearch'
require File.expand_path(File.dirname(__FILE__) + '/../lib/taggable')

RSpec.describe Taggable, "working w/ES" do

    INDEX = "test_tags"

    before(:each) do
        expect {
            @client = Elasticsearch::Client.new(log: true, trace: true)
            @client.indices.create(index:INDEX, 
                body: { 
                    mappings: {
                        properties: {
                            tags: { type: "keyword" } 
                        }
                    }
                }
            )
            a_cluser = Taggable.new("bluespar", "test", "cluster", "MAIN-B")  
            a_cluser.tags = ["VUL-1", "FIT"]   
            a_cluser.properties = {owner: "GPS", email: "gps@acme.corp"}       
            @client.index(index: INDEX, body: a_cluser.as_hash)
            sleep 2 #needed to let ES index the above doc
        }.not_to raise_error
    end

    after(:each) do 
        @client.indices.delete(index: INDEX)
    end

    describe "connecting and indexing a document" do
        it "as document works but it might be more efficient to do hash" do
            tagged_cluser = Taggable.new("bluespar", "SEG", "cluster", "MAIN-SEG")            
            response = @client.index(index: INDEX, body: tagged_cluser.as_document)
            expect(response['result']).to eq 'created'
        end

        it "must be a hash to index" do
            tagged_cluser = Taggable.new("spinnaker", "prod", "cluster", "MAIN")            
            response = @client.index(index: INDEX, body: tagged_cluser.as_hash)
            expect(response['result']).to eq 'created'
        end
    end

    describe "searching is easy too" do

        it "supports searching by item type" do
            search = @client.search(index: INDEX, 
                body: { 
                    query: { 
                        term: {
                            item: "cluster"
                        }
                    }
                }
            )

            expect(search['hits']['hits'].size).to eq 1
            for tmp_res in search['hits']['hits'] do
                a_doc = tmp_res['_source']
                expect(a_doc['name']).to eq "MAIN-B"
                expect(a_doc['application']).to eq "bluespar"
            end
        end

        it "supports searching by item type and application" do
            search = @client.search(index: INDEX, 
                body: { 
                    query: { 
                        bool: {
                            must: [
                                {match: { item: "cluster" }},
                                {match: { application: "bluespar" }}
                            ]
                        }
                    }
                }
            )

            expect(search['hits']['hits'].size).to eq 1
            for tmp_res in search['hits']['hits'] do
                a_doc = tmp_res['_source']
                expect(a_doc['name']).to eq "MAIN-B"
                expect(a_doc['application']).to eq "bluespar"
            end
        end

        it "searching by a tag is easy" do
            search = @client.search(index: INDEX, 
                body: { 
                    query: { 
                        terms: {
                            tags: ["FIT"]
                        }
                    }
                }
            )
            expect(search['hits']['hits'].size).to eq 1
            for tmp_res in search['hits']['hits'] do
                a_doc = tmp_res['_source']
                expect(a_doc['name']).to eq "MAIN-B"
            end
        end

        it "supports searching by properties like owner=gps" do
            search = @client.search(index: INDEX, 
                body: { 
                    query: { 
                        bool: {
                            must: [
                                {match: { "properties.owner" => "gps" }}
                            ]
                        }
                    }
                }
            )
            expect(search['hits']['hits'].size).to eq 1
            for tmp_res in search['hits']['hits'] do
                a_doc = tmp_res['_source']
                expect(a_doc['name']).to eq "MAIN-B"
            end
        end

        it "searching by tags should result in two" do
            tagged_cluser = Taggable.new("bluespar", "int", "cluster", "MAIN")  
            tags = ["test", "MPS"]
            tagged_cluser.tags = tags          
            response = @client.index(index: INDEX, body: tagged_cluser.as_hash)
            expect(response['result']).to eq 'created'
            sleep 1

            search = @client.search(index: INDEX, 
                body: { 
                    query: { 
                        terms: {
                            tags: ["FIT", "MPS"]
                        }
                    }
                }
            )

            expect(search['hits']['hits'].size).to eq 2
            for tmp_res in search['hits']['hits'] do
                a_doc = tmp_res['_source']
                expect(a_doc['application']).to eq "bluespar"
            end
        end
    end

    describe "updating a document is easy!" do
        it "should find a taggable by name and env and then update it's tags" do
            # https://stackoverflow.com/questions/44052659/elasticsearch-rails-multiple-must-not-working-correctly
            search = @client.search(index: INDEX, 
                body: { 
                    query: { 
                        bool: {
                            must: [
                                { match: { environment: "test" } },
                                { match: { application: "bluespar" } }
                            ]
                        }
                    }
                }
            )
            expect(search['hits']['hits'].size).to eq 1
            a_doc = search['hits']['hits'][0]['_source']
            expect(a_doc['name']).to eq "MAIN-B"
            expect(search['hits']['hits'][0]['_id'].nil?).to eq false
            document_id = search['hits']['hits'][0]['_id']            
            # find by id and update it w/new tags
            @client.update(index: INDEX, id: document_id, 
                body: {
                    doc: {
                        tags: ['FOO']
                    }
                }
            )
            sleep 1

            search_2 = @client.search(index: INDEX, 
                body: { 
                    query: { 
                        bool: {
                            must: [
                                { match: { environment: "test" } },
                                { match: { application: "bluespar" } }
                            ]
                        }
                    }
                }
            )
            expect(search_2['hits']['hits'].size).to eq 1
            a_doc_2 = search_2['hits']['hits'][0]['_source']
            expect(a_doc_2['tags'].size).to eq 1
            expect(a_doc_2['tags'][0]).to eq "FOO"
        end

        it "should find a taggable by name and env and then add new tags" do
            search = @client.search(index: INDEX, 
                body: { 
                    query: { 
                        bool: {
                            must: [
                                { match: { environment: "test" } },
                                { match: { application: "bluespar" } }
                            ]
                        }
                    }
                }
            )
            expect(search['hits']['hits'].size).to eq 1
            a_doc = search['hits']['hits'][0]['_source']
            expect(a_doc['name']).to eq "MAIN-B"
            expect(search['hits']['hits'][0]['_id'].nil?).to eq false
            document_id = search['hits']['hits'][0]['_id']            
            # find by id and update it w/new tags
            all_new_tags = ['FOO'] + a_doc['tags']
            @client.update(index: INDEX, id: document_id, 
                body: {
                    doc: {
                        tags: all_new_tags
                    }
                }
            )
            sleep 1

            search_2 = @client.search(index: INDEX, 
                body: { 
                    query: { 
                        bool: {
                            must: [
                                { match: { environment: "test" } },
                                { match: { application: "bluespar" } }
                            ]
                        }
                    }
                }
            )
            expect(search_2['hits']['hits'].size).to eq 1
            a_doc_2 = search_2['hits']['hits'][0]['_source']
            expect(a_doc_2['tags'].size).to eq 3
        end
    end

    describe "deleting should be easy too" do
        it "should support deleting a document by name + env" do
            # find it and then delete by its ID
            search = @client.search(index: INDEX, 
                body: { 
                    query: { 
                        bool: {
                            must: [
                                { match: { environment: "test" } },
                                { match: { application: "bluespar" } }
                            ]
                        }
                    }
                }
            )

            expect(search['hits']['hits'].size).to eq 1
            a_doc_id = search['hits']['hits'][0]['_id']
            expect(a_doc_id.nil?).to eq false

            expect {
                @client.delete(index: INDEX, id: a_doc_id)
            }.not_to raise_error
            
        end
    end
end