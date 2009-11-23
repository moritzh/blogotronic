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


 

end
