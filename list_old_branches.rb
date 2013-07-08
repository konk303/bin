#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pry'
require 'active_support/core_ext'

# = originから、releaseにマージ済みのbranchを削除
module ListOldBranches
  def self.initialize
    @wd = "#{Dir.home}/tmp/git"
    @out = "#{Dir.home}/work/release_note.txt"
    @repos = [:front, :back, :batch, :lws_framework]
    @branch_class = Struct.new :hash, :name, :time, :message
  end

  def self.execute
    initialize
    File.open(@out, "w") do |f|
      @repos.each do |repo|
        d = File.expand_path(repo.to_s, @wd)
        # ログを綺麗にみたいので、thread止める
        # threads << Thread.start(path, branches) do |d, branches|
        unless `cd #{d} && git status`.match("working directory clean")
          raise "#{d} not clean, no pull this time"
        end

        f.puts "#{repo}:"

        # fetch
        run_command("cd #{d} && git fetch --prune")
        # remote branchs with hash
        remotes = `cd #{d} && git ls-remote -h origin`.split("\n").map{|s|
          @branch_class.new(*s.split("\t")).tap{|o|
            o.name.sub!(%r{^refs/heads/}, "")
          }
        }
        # find branches that not yet merged to release
        not_mergeds = `cd #{d} && git branch -r --no-merged origin/release`.
          split("\n").
          grep(%r{^\s*origin/[hf]/}).map {|b|
          remotes.detect{|r| r.name == b.sub(%r{^\s*origin/}, "")}
        }

        # add more info
        not_mergeds.each do |branch|
          branch.message = `cd #{d} && git show -s --pretty=format:"%cn (%s)" #{branch.hash}`.chomp
          branch.time = Time.parse(`cd #{d} && git show -s --pretty=format:"%ci" #{branch.hash}`)
        end

        # list'em on note
        not_mergeds.select{|branch| branch.time < 1.week.ago}.sort_by(&:time).each do |branch|
          f.puts "  #{branch.name}:"
          f.puts "    #{branch.message}"
          f.puts "    - #{branch.hash}):"
          f.puts "    - last modified: #{branch.time}"
        end
      end
    end
  end

  def self.run_command(command)
    puts "execute: #{command}"
    raise unless system(command)
  end
end

ListOldBranches.execute
