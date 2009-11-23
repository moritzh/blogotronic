desc "run tests"
task :tests do |t|
  require 'test/unit'
  require 'rack/test'
  require 'main'
  Dir["./tests/*.rb"].each {|x| require x }
end

desc "bootstraps redis"
task :bootstrap do |t|
  require 'redis'
  r = Redis.new
  # bootstrapping log container
  r.push_tail('logs', nil)
  r.push_tail('blog_index',nil)
  r.push_tail('tags',nil)
end

desc "Reset Redis. ATTENTION: This kills everything, yeah."
task :reset do |t|
  puts 'killing all keys'
  require 'redis'
  r = Redis.new
  keys = r.keys('*')
  keys.each {|k| r.delete(k)}
  puts "killed #{keys.length} keys, bootstrapping now."
  Rake::Task['bootstrap'].execute
end