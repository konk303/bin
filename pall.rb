#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# = work下のprojectをgit pull (cleanだった場合のみ)
def run_command(command)
  puts "execute: #{command}"
  raise unless system(command)
end

threads = []
Dir.glob("#{Dir.home}/work/*/").select{|d| File.exists? "#{d}.git"}.each do |directory|
  unless `cd #{directory} && git status`.match("working directory clean")
    p "#{directory} not clean, no pull this time"
    next
  end
  threads << Thread.start(directory) do |d|
    run_command "cd #{d} && git checkout master && git pull -p"
    run_command "cd #{d} && git checkout develop && git merge origin/develop"
  end
end
threads.map(&:join)
