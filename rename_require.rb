#!/usr/bin/env ruby

require 'pry'

module Rewriter
  def self.execute
    puts "starting"
    base_dir = "#{Dir.home}/dev/rni/code/spec"
    globs = File.expand_path('**/*.{rb,feature}', base_dir)
    files = Dir.glob(globs)
    puts "checking #{files.size} files"
    files.each do |file|
      texts = File.read(file)
      # binding.pry
      if texts.include?('spec_helper')
        puts "  #{file}"
        File.open("#{file}", "w") {|f| f.puts texts.gsub('spec_helper', 'rails_helper') }
        # File.unlink(file)
      end
    end
    puts "finished"
  end
end

Rewriter.execute
