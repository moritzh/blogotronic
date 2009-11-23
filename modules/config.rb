configuration = YAML.load(File.read("./config.yml"))

def set_configuration(config,prefix="")
  if config.is_a?(Hash)
    config.each do |k,v|
      if v.is_a?(String)
        set "#{prefix}#{k}".to_sym, v
      elsif v.is_a?(Hash)
        set_configuration(v, "#{prefix}#{k}_")
      end
    end
  end
end
configure do |c|
  set :site_title, "Momos Blog" 
    set_configuration(configuration)
end

