require "sinatra"
require "sinatra/json"
require "sinatra/config_file"
require File.expand_path(File.dirname(__FILE__) + "/taggable")

config_file File.expand_path(File.dirname(__FILE__) + "../conf/config.yml")

configure do
  @factory = Taggable::TaggableFactory.new()
  @tag_thing = @factory.taggableInstance()
end

get "/applications" do 
  tags = params["tags"]

  if !tags.nil? 
    tag_array = tags.split(',')
    return find_all_by(:find_by_tags, tag_array)
  elsif params.size > 0 && tags.nil? 
    return find_all_by(:find_by_properties, params)
  else
    # for now - need to implement all applications
    not_found
  end
end

# returns a collection
def find_all_by(name, value)
  taggable_results = Taggable::SearchableApplication.public_send(name, value)
  return json "#{taggable_results.map(&:as_document)}"
end

get "/applications/:environment/:app_name" do |env, app|
  taggable_result = Taggable::SearchableApplication.find_by_name_and_env app, env
  json taggable_result.as_document
end

not_found do
  status 404
  "This route hasn't been implemented. Yet. "
end