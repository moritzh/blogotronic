

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