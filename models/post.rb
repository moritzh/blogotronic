require "yaml"

class Post
	attr_accessor :title, :slug, :body_html, :body_markdown, :date_created,  :tags

	def save_page(is_new = true)
		self.tags = Array.new
		self.save(is_new, "page")
	end
	
	def save_post(is_new = true)
		self.save(is_new, "post")
	end
	
	
	def save(is_new, type)
		self.slug = self.slug.downcase.gsub(/\W/,"_")
		my_srv = Redis.new		
		my_srv.set("#{type}_#{self.slug}", self.to_yaml)
		
		if is_new		
		my_srv.push_tail("blog_index", "#{type}_#{self.slug}")
		
		self.tags.each do |current_tag|
	            current_tag = current_tag.gsub(" ","_")
	            puts "tag_#{current_tag.downcase} -> post_#{self.slug}"
	            my_srv.push_tail("tag_#{current_tag.downcase}", "post_#{self.slug}")
	    end
		end
       
		puts "SAVED"
       end
    
    def rfc3339time
        require "time"
        self.date_created.xmlschema
    end


end
