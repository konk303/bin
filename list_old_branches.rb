#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pry'
require 'active_support/core_ext'
require 'active_resource'
require_relative 'redmine_config'

# = releaseにマージされないまま10日間以上たったbranchをリスト化
module ListOldBranches
  class Issue < ActiveResource::Base
    self.site = RedmineConfig::SITE
    self.user = RedmineConfig::USER
    self.password = RedmineConfig::PASSWORD
  end

  def self.initialize
    @wd = "#{Dir.home}/tmp/git"
    @out = "#{Dir.home}/work/release_note.txt"
    @repos = [:front, :back, :batch, :lws_framework]
    @branch_class = Struct.new :hash, :name, :committer, :time, :message, :has_ticket, :url, :status, :subject, :updated_at
    @committer_class = Struct.new :committer, :count
    @committers = []
  end

  def self.execute
    initialize
    buffer = []
    @repos.each do |repo|
      d = File.expand_path(repo.to_s, @wd)
      # ログを綺麗にみたいので、thread止める
      # threads << Thread.start(path, branches) do |d, branches|
      unless `cd #{d} && git status`.match("working directory clean")
        raise "#{d} not clean, no pull this time"
      end

      buffer << "#{repo}:"

      # fetch
      run_command("cd #{d} && git fetch --prune")
      # remote branches with hash
      remotes = `cd #{d} && git ls-remote -h origin`.split("\n").map{|s|
        @branch_class.new(*s.split("\t")).tap{|o|
          o.name.sub!(%r{^refs/heads/}, "")
        }
      }
      # find branches that not yet merged to release
      not_mergeds = `cd #{d} && git branch -r --no-merged origin/develop`.
        split("\n").
        grep(%r{^\s*origin/[hf]/}).map {|b|
        remotes.detect{|r| r.name == b.sub(%r{^\s*origin/}, "")}
      }

      # add more info
      not_mergeds.each do |branch|
        branch.committer, branch.time, branch.message =
          `cd #{d} && git show -s --pretty=format:"%cn || %ci || %s" #{branch.hash}`.
          chomp.split(" || ")
        branch.time = Time.parse(branch.time)
        if !(branch.name.include? "TBD") &&
            (issue_id = branch.name.match(%r{#(\d*)}).try(:[], 1)) &&
            (issue = Issue.find(issue_id, :params => {:key => RedmineConfig::API_KEY}))
          branch.has_ticket = true
          branch.url = "#{RedmineConfig::SITE}issues/#{issue_id}"
          branch.status = issue.status.name
          branch.subject = issue.subject
          branch.updated_at = issue.updated_on
        end
      end

      # select older than 10 days
      not_mergeds.select!{|branch| branch.time < 10.days.ago}

      # counts per person
      not_mergeds.each do |commit|
        committer =
          @committers.detect {|c| c.committer == commit.committer} ||
          @committer_class.new(commit.committer, 0).tap{|new_c| @committers << new_c}
        committer.count += 1
      end

      # list'em on note
      not_mergeds.sort_by(&:time).each do |branch|
        buffer << "  #{branch.name}:"
        buffer << "    #{branch.committer} (#{branch.message})"
        buffer << "      #{branch.time} - #{branch.hash}"
        if branch.has_ticket
          buffer << "    redmine: #{branch.status} (#{branch.updated_at})"
          buffer << "      #{branch.url} - #{branch.subject} "
        end
      end
    end

    # committer list on top
    buffer.unshift ""
    @committers.sort_by(&:count).each do |c|
      buffer.unshift "  #{c.committer} => #{c.count} branch#{c.count >= 2 ? "es" : "" }"
    end
    buffer.unshift "by name:"

    # write out
    File.open(@out, "w") do |f|
      buffer.flatten.each{|b| f.puts b}
    end
  end

  def self.run_command(command)
    puts "execute: #{command}"
    raise unless system(command)
  end
end

ListOldBranches.execute
