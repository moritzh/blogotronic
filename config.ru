require 'rubygems'
require 'sinatra'
require 'main'

root_dir = File.dirname(__FILE__)

set :environment, 'production'.to_sym
set :root,        root_dir
set :app_file,    File.join(root_dir, 'main.rb')
disable :run

run Sinatra::Application
