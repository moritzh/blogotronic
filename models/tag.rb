class Tag
  def self.get_top_tags
      rebuild_top_tags if !Post.srv.key?("top_tags") 
    YAML.load(Post.srv["top_tags"])
  end
  
  def self.rebuild_top_tags
    puts "building tag."
    Post.srv.delete("top_tags")
    data = Post.srv.keys("tag_*").sort_by{|tagname| Post.srv.list_length(tagname)}.reverse[0,10]
    Post.srv['top_tags'] = data.to_yaml
  end
end