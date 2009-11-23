class Tag
  def self.get_top_tags
    Post.srv.keys("tag_*").sort_by{|tagname| Post.srv.list_length(tagname)}.reverse[0,10]
  end
end