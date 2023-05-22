require "sinatra"
require "sinatra/json"
require "sinatra/config_file"
require File.expand_path(File.dirname(__FILE__) + "/taggable")

config_file File.expand_path(File.dirname(__FILE__) + "../conf/config.yml")

before do
  @factory = Taggable::TaggableFactory.new()
  @tag_thing = @factory.taggableInstance()
end

delete "/applications/:environment/:app_name" do |env, app|
  taggable_result = Taggable::SearchableApplication.find_by_name_and_env app, env
  taggable_result.delete
  json taggable_result.as_document
end

post "/applications/:environment/:app_name/:infra_type/:intra_name" do
  # check for existing app + env
  taggable = Taggable::SearchableApplication.find_by_name_and_env params["app_name"], params["environment"]
  posted_data = JSON.parse(request.body.read)
  if taggable.nil? # create it 
    @tag_thing.name = params["app_name"]
    @tag_thing.env = params["environment"]
    @tag_thing.infra_type = params["infra_type"]
    @tag_thing.infra_name = params["intra_name"]
    @tag_thing.tags = posted_data["tags"]
    @tag_thing.props = posted_data["properties"]
    @tag_thing.save
    json @tag_thing.as_document
  else
    unless posted_data["tags"].nil?
      taggable.tags = taggable.tags.nil? ? post_data["tags"] : (taggable.tags + posted_data["tags"]).uniq
    end
    unless posted_data["properties"].nil? 
      taggable.props = taggable.props.nil? ? posted_data["properties"] : taggable.props.merge(posted_data["properties"])
    end
    taggable.update
    json taggable.as_document
  end
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