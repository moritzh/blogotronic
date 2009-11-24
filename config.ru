require 'rubygems'
require 'sinatra'
require 'main'

root_dir = File.dirname(__FILE__)

set :environment, 'production'.to_sym
set :root,        root_dir
set :app_file,    File.join(root_dir, 'main.rb')
disable :run

log = File.new("#{root_dir}/sinatra.log", "a+")
$stdout.reopen(log)
$stderr.reopen(log)

run Sinatra::Application
