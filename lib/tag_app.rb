require "sinatra"
require "sinatra/json"



get "/" do
  json message: "Hello world"
end