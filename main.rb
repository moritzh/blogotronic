require "rubygems"
require "sinatra"
require "erb"
require "time"
require "redis"
require "modules/auth"

require "modules/helpers"
require "modules/cache"
require "yaml"
require "rdiscount"

configure do
  set :redis_srv, Redis.new
end

# Load the controllers
Dir["./controller/*.rb"]. each {|file| require file}


