require "rubygems"
require "sinatra"
require "erb"
require "time"
require "redis"
require "yaml"

require "modules/auth"
require "modules/config"
require "modules/helpers"
require "modules/cache"
require "models/post"
require "rdiscount"

configure do
  set :redis_srv, Redis.new
  set :environment, :production
  
end

# Load the controllers
Dir["./controller/*.rb"]. each {|file| require file}


