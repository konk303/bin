#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# = developのmergeが必要なbranchにdevelopをmergeしてpush
module MergeDevelopToBranches
  def self.initialize
    @wd = "#{Dir.home}/tmp/git"
    @merge_from = "develop"
    @update_branches = {
      :front => [
        "f/html",
        "f/spfp",
        "f/encrypt",
        "f/OrderPages"
      ],
      :back => [
        "f/html",
        "f/encrypt",
        # "f/SBITITR001",
        # "f/SBSMCTM006",
        # "f/SBSMCTM007",
        # "f/SBSMCTM009",
        # "f/SBSMCTM012",
        "f/SBSMCTM025"
      ],
      :batch => [
        "f/encrypt",
        "f/new_batch_201306"
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
      run_command("cd #{d} && git checkout #{@merge_from}")
      # update develop
      run_command("cd #{d} && git merge origin/#{@merge_from}")
      branches.each do |branch|
        # co branch
        run_command("cd #{d} && git checkout #{branch}")
        # update branch
        run_command("cd #{d} && git merge origin/#{branch}")
        # merge develop
        run_command("cd #{d} && git merge --no-ff #{@merge_from}")
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
