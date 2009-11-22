get '/' do
  redirect("/posts/1")
end

get '/page/:pagename/?' do
  record_stats
  my_server = options.redis_srv

  @recent_posts = [YAML::load(my_server.get("page_#{params[:pagename]}"))]
  @post_amount = 1

  #let's get the pages
  @pages = get_pages()

  @top_tags = my_server.keys("tag_*").sort_by{|tagname| my_server.list_length(tagname)}.reverse[0,10]
  @page_prefix = "/posts/"
  @page = 1
  @show_comments = false

  #	erb :entry_single
  erb :index

end


get '/posts/:nr/?' do
  record_stats
  my_server = options.redis_srv
  recent_posts_keys = my_server.list_range("blog_index", 0, -1).select{|item| item.include?("post_")}.reverse

  #let's get the pages
  @pages = get_pages()


  @post_amount = recent_posts_keys.size
  @page = params[:nr].to_i

  #check that we are in a "legal" page range, otherwise: goto page 1
  if @page > @post_amount / 10 or @page < 1 
    redirect("/page/1") unless @post_amount == 0
  end

  #getting the post keys we need
  post_from = ((@page -1) * 10)
  recent_posts_keys = recent_posts_keys[post_from,10]

  if recent_posts_keys.empty?
    #apparently, there are no posts so far
    recent_posts_yaml_array = Array.new
  else
    recent_posts_keys
    recent_posts_yaml_array = my_server.mget(recent_posts_keys)
  end

  @recent_posts = Array.new
  recent_posts_yaml_array.each do |entry|
    @recent_posts << YAML::load(entry)
  end


  @top_tags = ""
  #	@top_tags = my_server.keys("tag_*").sort_by{|tagname| my_server.list_length(tagname)}.reverse[0,10]
  @page_prefix = "/posts/"
  @show_comments = true
  erb :index
end








get '/:year/:month/:day/:slug/?' do
  record_stats
  my_server = options.redis_srv
  @recent_posts = [YAML::load(my_server.get("post_#{params[:slug]}"))]
  @post_amount = 1
  @pages = get_pages()
  @top_tags = my_server.keys("tag_*").sort_by{|tagname| my_server.list_length(tagname)}.reverse[0,10]
  @page_prefix = "/posts/"
  @page = 1
  @show_comments = true
  erb :index
end

get '/tag/:tagname/?' do redirect "/tag/#{params[:tagname]}/1" end

  get '/tag/:tagname/:nr/?' do
    record_stats
    my_server = options.redis_srv
    @page = params[:nr].to_i

    #let's get the pages
    @pages = Array.new
    my_keys = my_server.list_range("blog_index", 0, -1)
    @pages = get_pages()
    @top_tags = my_server.keys("tag_*").sort_by{|tagname| my_server.list_length(tagname)}.reverse[0,10]
    @recent_posts = Array.new
    post_from = (@page * 10) * -1
    post_to = post_from + 9
    current_post_keys = my_server.list_range("tag_#{params[:tagname].downcase}", post_from,  post_to).reverse
    current_post_keys .each do |index_key|
      post_obj = YAML::load(my_server.get(index_key))
      @recent_posts << post_obj 
    end

    @post_amount = my_server.list_length("tag_#{params[:tagname].downcase}")
    @top_tags = my_server.keys("tag_*").sort_by{|tagname| my_server.list_length(tagname)}.reverse[0,10]
    @page_prefix = "/tag/#{params[:tagname].downcase}/"
    @show_comments = true
    erb :index
  end