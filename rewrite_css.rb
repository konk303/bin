#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pry'

# == cssのurlをimage-url書き換えてファイル名をscss化
module RewriteCss
  def self.initialize(file_name_prefixes = [])
    # base_dir = "#{Dir.home}/work/front/app/assets/stylesheets/"
    # base_dir = "#{Dir.home}/work/front/app/assets/stylesheets/smart_phone"
    # base_dir = "#{Dir.home}/work/front/app/assets/stylesheets/mobile"

    # base_dir = "#{Dir.home}/work/front/app/assets/javascripts"
    base_dir = "#{Dir.home}/work/front/app/assets/javascripts/smart_phone"
    # base_dir = "#{Dir.home}/work/front/vendor/assets/stylesheets/fancybox"
    @files = [].tap do |files|
      [
        # "basic.css.scss",
        # "common.css.scss",
        # "shop.css.scss",
        # "top.css.scss",
        "common.js.erb"
        # "jquery.fancybox.css",
        # "helpers/jquery.fancybox-buttons.css"
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
      # crlf
      # replaced = texts.gsub(%r{\r\n}) {"\n"}
      # pc/css
      # replaced = texts.gsub(%r{url\("/img/(.*?)"\)}) {"image-url(\"pc/#{$1}\")"}
      # sp/css
      # replaced = texts.gsub(%r{url\(/(.*?)\)}) {"image-url(\"#{$1}\")"}
      # fp/css
      # replaced = texts.gsub(%r{url\("/(.*?)"\)}) {"image-url(\"#{$1}\")"}
      # pc/js
      # replaced = texts.gsub(%r{/img/(.*?)\.(jpeg|jpg|gif|png|bmp)}) {"<%= asset_path(\"pc/#{$1}.#{$2}\") %>"}
      # sp/js
      replaced = texts.gsub(%r{/(sp/images/.*?\.(jpeg|jpg|gif|png|bmp))}) {"<%= asset_path(\"#{$1}\") %>"}
      # fancybox
      # replaced = texts.gsub(%r{url\('(.*?)'\)}) {"image-url(\"sp/fancybox/#{$1}\")"}
      File.open("#{file}", "w") {|f| f.puts replaced}
    end
    puts "finished"
  end
end

RewriteCss.execute
