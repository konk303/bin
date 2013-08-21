#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# = developのmergeが必要なbranchにdevelopをmergeしてpush
module MergeDevelopToBranches
  def self.initialize
    @wd = "#{Dir.home}/tmp/git"
    @update_branches = {
      :front => [
        "sandbox",
      ],
      :back => [
        "sandbox",
      ],
      :batch => [
        "sandbox",
      ],
      :lws_framework => [
        "sandbox",
      ]
    }
  end

  def self.execute
    initialize
    threads = []
    @update_branches.each do |repo, branches|
      d = File.expand_path(repo.to_s, @wd)
      # ログを綺麗にみたいので、thread止める
      # threads << Thread.start(path, branches) do |d, branches|
      unless `cd #{d} && git status`.match("working directory clean")
        raise "#{d} not clean, no pull this time"
      end

      # fetch
      run_command("cd #{d} && git fetch")
      # co develop
      run_command("cd #{d} && git checkout develop")
      # update develop
      run_command("cd #{d} && git merge origin/develop")
      # co master
      run_command("cd #{d} && git checkout master")
      # update release
      run_command("cd #{d} && git merge origin/master")
      branches.each do |branch|
        merge_from = branch.match(%r{^h/}) ? :master : :develop
        # co branch
        run_command("cd #{d} && git checkout #{branch}")
        # update branch
        run_command("cd #{d} && git merge origin/#{branch}")
        # merge
        run_command("cd #{d} && git merge --no-ff #{merge_from}")
        # push branch
        run_command("cd #{d} && git push origin #{branch}")
      end
    end
  end

  def self.run_command(command)
    puts "execute: #{command}"
    raise unless system(command)
  end
end

MergeDevelopToBranches.execute
