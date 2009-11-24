# simple homepage bouncer.
get '/' do
  redirect("/posts/1")
end

# get a page by slug
get %r{/page/([a-zA-Z_]+)} do |num|
  record_stats
  @post = Post.get_by_name(num, :page)
  erb :single_post
end

# holding it up for a numerical index of pages.
get %r{/page/([0-9]+)} do |num|
  @page, @posts = Post.get_range(num,10,:page)
  erb :index
end

# same for posts, a simple paginated listing
get '/posts/:nr/?' do
  record_stats
  recent_posts_keys = Store.get.list_range("blog_index", 0, -1).select{|item| item.include?("post_")}.reverse

  @post_amount = recent_posts_keys.size
  @page = params[:nr].to_i

    #getting the post keys we need
  post_from = ((@page -1) * 10)
  recent_posts_keys = recent_posts_keys[post_from,10]

  if recent_posts_keys.empty?
    #apparently, there are no posts so far
    recent_posts_yaml_array = Array.new
  else
    recent_posts_keys
    recent_posts_yaml_array = Store.get.mget(recent_posts_keys)
  end

  @posts = Array.new
  recent_posts_yaml_array.each do |entry|
    @posts << YAML::load(entry)
  end
  @page_prefix = "/posts/"

  erb :index
end

# permalinko!
get '/:year/:month/:day/:slug/?' do
  record_stats
  my_server = Store.get
  @recent_posts = [YAML::load(my_server.get("post_#{params[:slug]}"))]
  @post_amount = 1
  
  @page_prefix = "/posts/"
  @page = 1
  @show_comments = true
  @post = @recent_posts.first
  @title = @post.title
  erb :single_page
end

# simple redirect
get '/tag/:tagname/?' do redirect "/tag/#{params[:tagname]}/1" end
  
get '/tag/:tagname/:nr/?' do
  # The necessarities of life
  @flash = "Showing all posts and pages for tag #{params[:tagname]}"
  @title = "pages and posts containing #{params[:tagname]}"
  record_stats
  my_server = Store.get
  @page = params[:nr].to_i

  #let's get the pages
  @pages = Array.new
  my_keys = my_server.list_range("blog_index", 0, -1)
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
  @posts = @recent_posts
  erb :index
end