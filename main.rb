require "rubygems"
require "sinatra"
require "erb"
require "time"
require "redis"
require "models/post.rb"
require "modules/auth.rb"
require "yaml"
require "rdiscount"

configure do
  set :redis_srv, Redis.new
end


helpers do
  include Sinatra::Authorization

  def record_stats

    current_time = Time.now.to_s
    #/post/bla
    path = request.path
    #Mozilla/5.0 (X11; U; Linux x86_64; en-US) [...] 
    user_agent = request.user_agent
    #IP
    user_ip = request.ip
    #where from
    user_referer = request.referer
    stats = [current_time, user_ip, user_agent, user_referer, path]

    options.redis_srv.list_trim('logs', -500, -1)
    options.redis_srv.push_tail 'logs', stats.join(" | ")


  end


  def get_pages
    pages = Array.new
    #let's get the pages
    pages_keys = options.redis_srv.keys("page_*")
    if !pages_keys.nil?
      pages_keys = pages_keys.sort
      pages_keys.each do |entry|
        pages << entry.gsub("page_","")
      end
      pages
    else
      []
    end
  end

end


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

get '/feed/?' do
  redirect ("/feed/atom")
end

get '/feed/:format/?' do
  my_server = options.redis_srv
  recent_posts_keys = my_server.list_range("blog_index", 0, -1).select{|item| item.include?("post_")}[-10,10]

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




get '/admin/index/?' do
  require_administrative_privileges
  erb :admin_index
end

get '/admin/stats/?' do
  require_administrative_privileges
  @statistics = options.redis_srv.list_range('logs', 0, -1)
  @statistics.map! {|item| item.split("|") }
  erb :admin_stats

end


get '/admin/entry/new' do
  require_administrative_privileges
  erb :entry_new
end

get '/admin/entry/edit/?' do
  require_administrative_privileges
  my_server = options.redis_srv
  @post_list = my_server.list_range("blog_index",0,-1).reverse
  erb :entry_edit_index
end

get '/admin/entry/edit/:slug' do
  require_administrative_privileges
  my_server = options.redis_srv
  @my_post = YAML::load(my_server.get(params[:slug]))

  if params[:slug].include?("page_")
    @type = "page"
  elsif params[:slug].include?("post_")
    @type = "post"
  end
  erb :entry_edit_single
end



get '/admin/entry/delete' do
  require_administrative_privileges
  my_server = options.redis_srv
  @post_list = my_server.list_range("blog_index",0,-1).reverse
  erb :entry_delete_index
end

get '/admin/entry/delete/:slug' do
  require_administrative_privileges
  my_server = options.redis_srv
  if (my_server.key?(params[:slug]))
    my_post = YAML::load(my_server.get(params[:slug]))
    #let's remove all the references to the post in tags
    my_post.tags.each do |current_tag|
      my_server.list_rm("tag_#{current_tag}", 1, params[:slug])
    end        
    my_server.delete("post_#{params[:slug]}")
    my_server.list_rm("blog_index", 1, params[:slug])    
  end

  "Deleted entry: #{params[:slug]}<br/> <a href=\"/admin/index\">back</a>"
end


post '/admin/entry/new' do
  require_administrative_privileges

  current_post = Post.new
  current_post.date_created = Time.now
  current_post.tags = params[:tags].gsub(", ",  ",").split(",")
  current_post.title = params[:title]
  current_post.slug = params[:title].gsub(" ","_")
  current_post.body_markdown = params[:body]
  current_post.body_html = RDiscount.new(params[:body]).to_html

  if params[:type] == "post"
    current_post.save_post(true)
  elsif params[:type] == "page"
    current_post.save_page(true)
  end

  'Post has been saved (<a href="/">back</a>)'
end


post '/admin/entry/edit/:slug' do
  require_administrative_privileges

  current_post = YAML::load(options.redis_srv.get(params[:slug]))
  current_post.body_markdown = params[:body]
  current_post.body_html = RDiscount.new(params[:body]).to_html

  if params[:type] == "post"
    current_post.save_post(false)
  elsif params[:type] == "page"
    current_post.save_page(false)
  end
  'Entry has been saved (<a href="/admin/index">back</a>)'
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
