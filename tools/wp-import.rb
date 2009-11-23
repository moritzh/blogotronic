#!/usr/bin/ruby
# import a wordpress blog, it's posts, to blogotronic
require 'rubygems'
require 'mysql'
require 'redis'
require '../models/post.rb'
begin
  # connect to the MySQL server
  dbh = Mysql.real_connect(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
  # get server version string and display it
  puts "Server version: " + dbh.get_server_info
  @prefix =  ARGV[4]
  res = dbh.query("Select #{@prefix}posts.id as id, #{@prefix}posts.post_title as title, #{@prefix}posts.post_content as content, #{@prefix}posts.post_date as date, #{@prefix}posts.post_type as type from #{@prefix}posts")
  res.each_hash do |post|
    p = Post.new
    p.title = post['title']
    p.slug = post['title']
    p.body_html = post['content']
    p.date_created = post['date']
    @taglist = []
    tags = dbh.query("select #{@prefix}terms.name as tag from #{@prefix}terms,#{@prefix}term_taxonomy,#{@prefix}term_relationships where #{@prefix}term_relationships.object_id = #{post['id']} and #{@prefix}term_taxonomy.term_taxonomy_id = #{@prefix}term_relationships.term_taxonomy_id and #{@prefix}terms.term_id = #{@prefix}term_taxonomy.term_id")
    tags.each_hash do |tag|
      @taglist << tag['tag']
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
  puts "someth
  ing went wrong. #{e}"
  puts e.trace
ensure
  # disconnect from server
  dbh.close if dbh
end