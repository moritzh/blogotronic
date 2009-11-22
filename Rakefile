desc "run tests"
task :tests do |t|
  require 'test/unit'
  require 'rack/test'
  require 'main'
  Dir["./tests/*.rb"].each {|x| require x }
end