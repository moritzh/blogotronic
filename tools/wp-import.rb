#!/usr/bin/ruby
# import a wordpress blog, it's posts, to blogotronic
require 'rubygems'
require 'mysql'
require 'redis'
require 'iconv'
require '../models/post.rb'
begin
  # connect to the MySQL server
  dbh = Mysql.real_connect(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
  # get server version string and display it
  # the server encoding, for iconv
  server_encoding = dbh.character_set_name
  
  @prefix =  ARGV[4]
  res = dbh.query("Select #{@prefix}posts.id as id, #{@prefix}posts.post_title as title, #{@prefix}posts.post_content as content, #{@prefix}posts.post_date as date, #{@prefix}posts.post_type as type from #{@prefix}posts")
  res.each_hash do |post|
    p = Post.new
    p.title = Iconv.conv('utf8',server_encoding,post['title'])
    p.slug = Iconv.conv('utf8',server_encoding,post['title'])
    p.body_html = Iconv.conv('utf8',server_encoding,post['content'])
    p.date_created = Iconv.conv('utf8',server_encoding,post['date'])
    @taglist = []
    tags = dbh.query("select #{@prefix}terms.name as tag from #{@prefix}terms,#{@prefix}term_taxonomy,#{@prefix}term_relationships where #{@prefix}term_relationships.object_id = #{post['id']} and #{@prefix}term_taxonomy.term_taxonomy_id = #{@prefix}term_relationships.term_taxonomy_id and #{@prefix}terms.term_id = #{@prefix}term_taxonomy.term_id")
    tags.each_hash do |tag|
      @taglist << Iconv.conv('utf8',server_encoding,tag['tag'])
    end
    p.tags = @taglist
    puts post['type']
    if post['type'] == 'post'
      p.save_post
    elsif post['type'] == 'page'
      p.save_page
    end
  end
rescue Exception => e
  puts "something went wrong. #{e}"
  puts e.trace
ensure
  # disconnect from server
  dbh.close if dbh
end