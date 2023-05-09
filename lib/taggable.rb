
require 'elasticsearch'

module Taggable

    class TaggableFactory

        attr_accessor :es_client, :es_index_name

        def initialize(connection_properties={}, index_name = "test_tags")
            @es_client = Elasticsearch::Client.new(log: true, trace: true)
            @index_name = index_name
        end

        def taggableInstance
            Taggable::SearchableApplication.es_client = @es_client
            Taggable::SearchableApplication.es_index_name = @index_name
            taggable = Taggable::SearchableApplication.new
            # taggable.es_client = @es_client
            # taggable.es_index_name = @index_name
            return taggable
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

        class << self
            attr_accessor :es_client, :es_index_name
        end

        def es_client
            self.class.es_client
        end

        def es_index_name
            self.class.es_index_name
        end

        # :es_client, :es_index_name,
        attr_accessor :es_doc_id

        def valid?
            return !!@name && !!@env
        end

        # must have at least an application name and env
        def save
            raise Exception.new "invalid SearchableApplication -- there must be an application name" if valid? == false
            response = es_client.index(index: es_index_name, body: self.as_hash)
            return response[:_id]
        end
        
        # must provide app and env
        def delete
            raise Exception.new "cannot delete w/o name and env" if valid? == false
            taggable = find_by_name_and_env(@name, @env)
            es_client.delete(index: es_index_name, id: taggable.es_doc_id)
        end

        # This should be a class method but then how does it get connection info?
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
                nil
            end
        end
        
        def taggable_from_es_response(source_response)
            @es_doc_id = source_response['_id']
            @name = source_response['_source']['application']
            @env = source_response['_source']['enviornment']
            @infra_type = source_response['_source']['infra_type']
            @infra_name = source_response['_source']['infra_name']
            @tags = source_response['_source']['tags']
            @props = source_response['_source']['props']
            return self
        end
    end

end