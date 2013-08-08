#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# = originから、releaseにマージ済みのbranchを削除
module PruneRemoteBranches
  def self.initialize
    @wd = "#{Dir.home}/tmp/git"
    @repos = [:front, :back, :batch, :lws_framework]
  end

  def self.execute
    initialize
    @repos.each do |repo|
      d = File.expand_path(repo.to_s, @wd)
      # ログを綺麗にみたいので、thread止める
      # threads << Thread.start(path, branches) do |d, branches|
      unless `cd #{d} && git status`.match("working directory clean")
        raise "#{d} not clean, no pull this time"
      end

      # fetch
      run_command("cd #{d} && git fetch --prune")
      # find hotfix branches that already merged to release
      deletes = `cd #{d} && git branch -r --merged origin/release`.split("\n").
        grep(%r{^\s*origin/h/}).map{|b| b.sub(%r{^\s*origin/}, "")}
      # find feature branches that already merged to release
      deletes |= `cd #{d} && git branch -r --merged origin/develop`.split("\n").
        grep(%r{^\s*origin/f/}).map{|b| b.sub(%r{^\s*origin/}, "")}
      puts "  delete #{deletes.size} remote branches"
      deletes.each do |branch|
        # puts "cd #{d} && git push origin :#{branch}"
        run_command("cd #{d} && git push origin :#{branch}")
      end
      # fetch again and gc
      run_command("cd #{d} && git fetch --prune")
      run_command("cd #{d} && git gc")
      # also gc work/
      run_command("cd ~/work/#{repo} && git fetch --prune")
      run_command("cd ~/work/#{repo} && git gc")
    end
  end

  def self.run_command(command)
    puts "execute: #{command}"
    raise unless system(command)
  end
end

PruneRemoteBranches.execute
