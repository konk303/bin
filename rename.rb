#!/usr/bin/env ruby

require 'pry'

module Rewriter
  def self.execute
    puts "starting"
    base_dir = "#{Dir.home}/dev/mycomment-rails/app/assets/stylesheets/mobile"
    globs = File.expand_path('*.{css}', base_dir)
    files = Dir.glob(globs)
    puts "checking #{files.size} files"
    files.each do |file|
      texts = File.read(file)
      # binding.pry
      if texts.include?('url(../')
        puts "  #{file}"
        File.open("#{file}", "w") {|f| f.puts texts.gsub('url(../', 'url(/') }
        # File.unlink(file)
      end
    end
    puts "finished"
  end
end

Rewriter.execute
