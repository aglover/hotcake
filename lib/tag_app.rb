require "sinatra"
require "sinatra/json"
require File.expand_path(File.dirname(__FILE__) + '/taggable')


get "/applications/:environment/:app_name" do |env, app|
  factory = Taggable::TaggableFactory.new()
  tag_thing = factory.taggableInstance()
  
  taggable_result = Taggable::SearchableApplication.find_by_name_and_env app, env

  json taggable_result.as_document
end