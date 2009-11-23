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
       
		puts "SAVED"
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


end
