class PagesTest < Test::Unit::TestCase
  include Rack::Test::Methods
  
  # too lazy to test right now, just need the structure.
  def test_homepage_redirect
    get '/'
    follow_redirect!
    assert_equal "http://example.org/posts/1", last_request.url
  end
  
  def app
    Sinatra::Application
  end
end