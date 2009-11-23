get '/feed/?' do
  redirect ("/feed/atom")
end

get '/feed/:format/?' do
  my_server = options.redis_srv
  recent_posts_keys = Post.srv.list_range("blog_index", 0, -1).select{|item| item.include?("post_")}

  if recent_posts_keys.nil?
    recent_posts_yaml_array = []
  else
    recent_posts_yaml_array = my_server.mget(recent_posts_keys)
  end


  @recent_posts = Array.new
  recent_posts_yaml_array.reverse.each do |post|
    @recent_posts << YAML::load(post)
  end


  if params[:format] == "rss"
    erb :rss
  elsif params[:format] == "atom"
    erb :atom
  else
    error(404)
  end

end
