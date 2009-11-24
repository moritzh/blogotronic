require "rubygems"
require "sinatra"
require "erb"
require "time"
require "yaml"
require "logger"
require "modules/auth"
require "modules/config"
require "modules/store"
require "modules/helpers"
require "modules/cache"
require "models/post"
require "models/tag"

require "rdiscount"

configure do

  set :environment, :production
  set :logger, Logger.new("sinatra.log") 
end

# Load the controllers
Dir["./controller/*.rb"]. each {|file| require file}


