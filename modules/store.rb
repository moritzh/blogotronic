# Simple Wrapper for redis calls
require 'redis'
class Store
  def self.get
    @@store ||= Redis.new
    return @@store
  end
end