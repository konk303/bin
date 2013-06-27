#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# = work下のprojectをgit pull (cleanだった場合のみ)
threads = []
Dir.glob("#{Dir.home}/work/*").each do |directory|
  next unless File::ftype(directory) == "directory"
  next unless File.exists? "#{directory}/.git"
  unless `cd #{directory} && git status`.match("working directory clean")
    p "#{directory} not clean, no pull this time"
    next
  end
  threads << Thread.start(directory) do |d|
    command = "cd #{d} && git co release && git pull -p"
    puts "execute: #{command}"
    system command
    command = "cd #{d} && git co develop && git merge origin/develop"
    puts "execute: #{command}"
    system command
    command = "cd #{d} && git co f/encrypt && git merge origin/f/encrypt"
    puts "execute: #{command}"
    system command
  end
end

threads.map(&:join)
