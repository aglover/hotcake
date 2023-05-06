
module Taggable

    class TaggableFactory


        def initialize(connection_properties={})
        end

        def manufactureTaggable
            Taggable::Application.new()
        end

    end

    class Application
        
        attr_accessor :name, :env, :infra_type, :infra_name, :tags, :props

        
        # def initialize(application, environment, item=nil, name=nil, tags=[], properties={})
        #     @name = application
        #     @env = environment
        #     @infra_type = item
        #     @infra_name = name
        #     @tags = tags
        #     @props = properties
        # end


        def save()
        end

        

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

end