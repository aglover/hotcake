
require 'elasticsearch'

module Taggable

    class TaggableFactory

        def initialize(connection_properties={}, index_name = "test_tags")
            @es_client = Elasticsearch::Client.new(log: true, trace: true)
            @index_name = index_name
        end

        def manufactureTaggable
            taggable = Taggable::SearchableApplication.new
            taggable.es_client = @es_client
            taggable.es_index_name = @index_name
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
                document[:item_type] = @infra_type
                document[:item_name] = @infra_name
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

        attr_accessor :es_client, :es_index_name

        def save
            response = @es_client.index(index: @es_index_name, body: self.as_hash)
            return response[:_id]
        end
        
    end

end