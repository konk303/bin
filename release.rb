#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# = release branchを作成してfinish(結果的にdevelop -> master のマージ)
module UpdateReleaseBranchAndPush
  def self.initialize
    @wd = "#{Dir.home}/tmp/git"
    @release_branch = "master"
    @release_tag_prefix = "ST_VER"
    @release_tag_message_prefix = "st release"
    @repos = [:front, :back, :batch, :lws_framework]
  end

  def self.execute
    initialize
    threads = []
    @repos.each do |repo|
      d = File.expand_path(repo.to_s, @wd)
      # ログを綺麗にみたいので、thread止める
      # threads << Thread.start(path) do |d|
      unless `cd #{d} && git status`.match("working directory clean")
        raise "#{d} not clean, no pull this time"
      end

      tag_name = Time.new.strftime("#{@release_tag_prefix}%Y%m%d%H%M")
      tag_message = Time.new.strftime("#{@release_tag_message_prefix} %F %R")
      # fetch
      run_command("cd #{d} && git fetch")
      # co develop
      run_command("cd #{d} && git checkout develop")
      # update develop
      run_command("cd #{d} && git merge origin/develop")
      # co release
      run_command("cd #{d} && git checkout #{@release_branch}")
      # update release
      run_command("cd #{d} && git merge origin/#{@release_branch}")
      # git flow release start
      run_command("cd #{d} && git flow release start #{tag_name}")
      # git flow release finish
      run_command("cd #{d} && git flow release finish -m'#{tag_message}' #{tag_name}")
      # push release
      # run_command("cd #{d} && git push origin #{@release_branch}")
      # push develop
      # run_command("cd #{d} && git push origin develop")
      # push tag
      # run_command("cd #{d} && git push --tags")
    end
  end

  def self.run_command(command)
    puts "execute: #{command}"
    raise unless system(command)
  end
end

UpdateReleaseBranchAndPush.execute
