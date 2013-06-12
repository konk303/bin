#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pry'

# == cssのurlをimage-url書き換えてファイル名をscss化
module RewriteCss
  def self.initialize(file_name_prefixes = [])
    base_dir = "#{Dir.home}/work/front/app/assets/stylesheets/mobile"
    # base_dir = "#{Dir.home}/work/front/app/assets/stylesheets/smart_phone"
    # base_dir = "#{Dir.home}/work/front/app/assets/stylesheets/"
    @files = [].tap do |files|
      [
        # "basic.css",
        "common.css",
        # "item.css",
        # "shop.css",
        # "top.css",
      ].each{|css| files << File.expand_path(css, base_dir)}
      # 1.upto(26) do |i|
      #   ["a", "b"].each do |ab|
      #     files << File.expand_path("color-variation/#{ab}-#{i}.css", base_dir)
      #   end
      # end
    end
  end

  def self.execute
    initialize
    puts "starting"
    @files.each do |file|
      texts = File.read(file)
      # replaced = texts
      replaced = texts.gsub(%r{url\("/(.*?)"\)}) {"image-url(\"#{$1}\")"}
      # replaced = texts.gsub(%r{url\(/(.*?)\)}) {"image-url(\"#{$1}\")"}
      # replaced = texts.gsub(%r{url\(/img/(.*?)\)}) {"image-url(\"#{$1}\")"}
      File.open("#{file}.scss", "w") {|f| f.puts replaced}
    end
    puts "finished"
  end
end

RewriteCss.execute
