#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#= work下のprojectを起動
threads = []
Dir.glob("#{Dir.home}/work/*").each do |directory|
  if File::ftype(directory) == "directory" && File.exists?("#{directory}/script/rails")
    threads << Thread.start(directory) do |d|
      p "starts rails on #{d}"
      system("cd #{d} && rails s")
    end
  end
end

threads.map(&:join)
