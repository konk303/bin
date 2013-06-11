#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pry'

# == cssから正規表現にマッチする行を探す
module GrepCss
  def self.initialize(file_name_prefixes = [])
    @regexps = [
      %r{^\s*/[^/\*]},
      %r{\\}
    ]

    @glob = "#{Dir.home}/work/front/app/assets/stylesheets/**/*{.css,.scss}"
  end

  def self.execute
    initialize
    puts "starting"
    Dir.glob(@glob).each do |file|
      File.readlines(file).each_with_index do |line, i|
        @regexps.each do |regexp|
          if line =~ regexp
            puts "#{file.sub("#{Dir.home}/work/front/app/assets/stylesheets/", "")} L#{i.succ}: #{line}"
          end
        end
      end
    end
    puts "finished"
  end
end

GrepCss.execute
