require "yaml"
require 'benchmark'

class Post
	attr_accessor :title, :slug, :body_html, :body_markdown, :date_created,  :tags

	def save_page(is_new = true)
		self.tags = Array.new
		self.save(is_new, "page")
	end
	
	def save_post(is_new = true)
		self.save(is_new, "post")
	end
	
	def self.srv
	  @@my_srv ||= Redis.new
  end
	
	def srv
	  self.class.srv
  end
	
	def save(is_new, type)
		self.slug = self.slug.downcase.gsub(/\W/,"_")
		srv.set("#{type}_#{self.slug}", self.to_yaml)
		
		if is_new		
		self.srv.push_tail("blog_index", "#{type}_#{self.slug}")
		
		self.tags.each do |current_tag|
	            current_tag = current_tag.gsub(" ","_")
	            puts "tag_#{current_tag.downcase} -> post_#{self.slug}"
	            self.srv.push_tail("tag_#{current_tag.downcase}", "post_#{self.slug}")
	    end
		end
    Tag.rebuild_top_tags
   end
    
    def rfc3339time
        require "time"
        self.date_created.xmlschema
    end
    
    # let's do the model stuff here.
    def self.get_by_name(pagename,type=:post)
      data = srv.get("#{type.to_s}_#{pagename}")
      if data
        YAML.load(data)
      else
        nil
      end
    end
    
    def self.get_range(offset, limit, type)
     
      offset = offset.to_i
      
        data = srv.list_range("blog_index",0,-1).select{|item| item.include?("#{type.to_s}_")}.reverse
        
      if data.length >= (offset-1) * limit + limit
        offset = offset
      else
        offset = data.length / limit
        
      end
      @items = []
      data[offset,limit].each { |d| @items << YAML.load(srv[d]) }

      return offset,@items
    end
    # ruby 1.8.7 hack
    def date_xmlschema
      # CCYY-MM-DDThh:mm:ssTZD
      self.date.strftime("%Y-%m-%dT%H:%M:%S")
    end

end

class Page
    def self.get_all_pages
       pages = Array.new
       #let's get the pages
       pages_keys = Post.srv.keys("page_*")
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
