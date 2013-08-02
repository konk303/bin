#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pry'

# == crlfを探す
module CrLf
  def self.execute
    puts "starting"
    base_dir = "#{Dir.home}/work"
    repos = [:front, :back, :batch, :lws_framework]
    globs = repos.map{|repo| "#{File.expand_path(repo.to_s, base_dir)}/**/*.{rb,erb,js,css,scss,yml,yaml}"}
    files = Dir.glob(globs)
    puts "checking #{files.size} files"
    files.each do |file|
      texts = File.read(file)
      if texts =~ %r{\r\n}
        puts "  #{file}"
        # File.open("#{file}", "w") {|f| f.puts texts.gsub(%r{\r\n}) {"\n"}}
      end
    end
    puts "finished"
  end
end

CrLf.execute
