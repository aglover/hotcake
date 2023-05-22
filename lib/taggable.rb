
require 'elasticsearch'

module Taggable

    class TaggableFactory

        attr_accessor :es_client, :es_index_name

        def initialize(connection_properties={}, index_name = "test_tags")
            @es_client = Elasticsearch::Client.new(log: true, trace: false)
            @index_name = index_name
        end

        def taggableInstance
            Taggable::SearchableApplication.es_client = @es_client
            Taggable::SearchableApplication.es_index_name = @index_name
            return Taggable::SearchableApplication.new
        end

    end

    class Application 
        
        attr_accessor :name, :env, :infra_type, :infra_name, :tags, :props

        def as_hash
            document = {
                :application => @name, 
                :environment => @env
            }

            if !@infra_type.nil? and !@infra_name.nil? 
                document[:infra_type] = @infra_type
                document[:infra_name] = @infra_name
            end
            
            if !tags.nil? && tags.size > 0 
                document[:tags] = @tags
            end
            
            if !props.nil? && props.size > 0
                document[:properties] = @props
            end
            return document
        end

        def as_document
            as_hash().to_json()
        end
    end

    class SearchableApplication < Taggable::Application

        attr_accessor :es_doc_id

        def valid?
            return !!@name && !!@env
        end

        # must have at least an application name and env
        # todo evenutally make this method smart enough to update an existing app + env
        def save
            raise Exception.new "invalid SearchableApplication -- there must be an application name" if valid? == false
            response = es_client.index(index: es_index_name, body: self.as_hash)
            self.es_doc_id = response['_id']
            return self.es_doc_id
        end
        
        # there must be an id
        def update
            raise Exception.new "this instance lacks an ID - have you saved it?" if self.es_doc_id.nil?
            es_client.update(index: es_index_name, id: self.es_doc_id, 
                body: { doc: self.as_hash() }
            )
        end

        # must provide app and env
        def delete
            raise Exception.new "cannot delete w/o name and env" if valid? == false
            taggable = Taggable::SearchableApplication.find_by_name_and_env(@name, @env)
            es_client.delete(index: es_index_name, id: taggable.es_doc_id)
        end
        
        def es_client
            self.class.es_client
        end

        def es_index_name
            self.class.es_index_name
        end

        class << self 

            attr_accessor :es_client, :es_index_name

            def find_by_tags(tags=[])
                result = es_client.search(index: es_index_name, 
                    body: { 
                        query: { terms: { tags: tags } }
                    }
                )
                return result['hits']['hits'].size > 0 ? build_response(result) : []
            end

            def find_by_properties(props={})
                match_queries = []
                props.each { |key, value| 
                    match_queries <<  { match: { "properties.#{key}" => "#{value}" }}
                }

                result = es_client.search(index: es_index_name, 
                    body: { 
                        query: { bool: { must: match_queries } }
                    }
                )
                return result['hits']['hits'].size > 0 ? build_response(result) : []
            end

            # there can only be one! 
            def find_by_name_and_env(application_name, environment)
                result =  es_client.search(index: es_index_name, 
                    body: { 
                        query: { 
                            bool: {
                                must: [
                                    { match: { environment: "#{environment}" } },
                                    { match: { application: "#{application_name}" } }
                                ]
                            }
                        }
                    }
                )
                if result['hits']['hits'].size > 0
                    return taggable_from_es_response(result['hits']['hits'][0])
                else
                    return nil
                end
            end
            
            def build_response(es_response_hash)
                docs = []
                es_response_hash['hits']['hits'].each { | doc |
                    docs << taggable_from_es_response(doc)
                }
                return docs
            end

            def taggable_from_es_response(source_response)
                taggable = Taggable::SearchableApplication.new
                taggable.es_doc_id = source_response['_id']
                taggable.name = source_response['_source']['application']
                taggable.env = source_response['_source']['environment']
                taggable.infra_type = source_response['_source']['infra_type']
                taggable.infra_name = source_response['_source']['infra_name']
                taggable.tags = source_response['_source']['tags']
                taggable.props = source_response['_source']['properties']
                return taggable
            end
        end
    end

end