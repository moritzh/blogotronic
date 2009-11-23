
class Configuration
  def self.store
    @@store ||= {}
  end
  
  def self.set_configuration(config,prefix="")
    if config.is_a?(Hash)
      config.each do |k,v|
        if v.is_a?(String)
          store["#{prefix}#{k}".to_sym]=  v
        elsif v.is_a?(Hash)
          set_configuration(v, "#{prefix}#{k}_")
        end
      end
    end
  end
  
  def self.[](key)
    store[key]
  end
end

configuration = YAML.load(File.read("./config.yml"))
Configuration.set_configuration(configuration)
