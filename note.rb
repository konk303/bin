#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pry'
require 'active_support/core_ext'

# = merge commitのログからnoteを作成
# （可能ならrelease branchを触る時に入れ込みたい）
module CreateReleaseNote
  def self.initialize
    @wd = "#{Dir.home}/tmp/git"
    @out = "#{Dir.home}/work/release_note.txt"
    @release_branch = "release"
    @develop_branch = "develop"
    @deploy_tag_regex = %r{^CT_DEPLOY}
    @release_tag_regex = %r{^CT_VER}
    @hotfix_branch_regex = %r{.*Merge branch 'h/(.*?)' into #{@release_branch}}
    @feature_branch_regex = %r{.*Merge branch 'f/(.*?)' into #{@develop_branch}}
    @repos = [:front, :back, :batch]
  end

  def self.execute
    initialize
    File.open(@out, "w") do |f|
      @repos.each do |repo|
        d = File.expand_path(repo.to_s, @wd)
        unless `cd #{d} && git status`.match("working directory clean")
          raise "#{d} not clean, no pull this time"
        end

        f.puts "#{repo}:"

        # fetch
        run_command("cd #{d} && git fetch")

        tags = `cd #{d} && git tag -l`.split("\n")
        deploy_tags = tags.grep(@deploy_tag_regex).sort.reverse.
          unshift("HEAD").push("C_201305151645")
        release_tags = tags.grep(@release_tag_regex).sort.reverse.
          unshift("HEAD").push("C_201305151645")
        log_command = "cd #{d} && git log --oneline --merges"

        # release note for release per deploy (/h merges on prev_tag..current_tag)
        if deploy_tags.any?
          # co release
          run_command("cd #{d} && git checkout #{@release_branch}")
          # update release
          run_command("cd #{d} && git merge origin/#{@release_branch}")

          f.puts "  release merges:"
          deploy_tags.reduce do |prev, current|
            deploy_commits = "#{current}..#{prev}"
            deploy_merges = `#{log_command} #{deploy_commits}`.split("\n").
              grep(@hotfix_branch_regex).
              map{|commit|
              commit.sub(@hotfix_branch_regex){$1}}.
              sort.uniq
            # next current unless deploy_merges.any?
            f.puts "    #{prev.sub(@deploy_tag_regex, "")}:"
            deploy_merges.each {|commit| f.puts "      #{commit}"}
            current
          end
        end

        # release note for develop per release (/f merges on prev_tag..current_tag)
        if release_tags.any?
          # co develop
          run_command("cd #{d} && git checkout #{@develop_branch}")
          # update develop
          run_command("cd #{d} && git merge origin/#{@develop_branch}")

          f.puts "  develop merges:"
          release_tags.reduce do |prev, current|
            develop_commits = "#{current}..#{prev}"
            develop_merges = `#{log_command} #{develop_commits}`.split("\n").
              grep(@feature_branch_regex).
              map{|commit|
              commit.sub(@feature_branch_regex){$1}}.
              sort.uniq
            # next current unless develop_merges.any?
            f.puts "    #{prev.sub(@release_tag_regex, "")}:"
            texts = develop_merges.in_groups_of(7, false).map{|grouped|
              "      #{grouped.join(", ")},"
            }.join("\n")

            f.puts texts.chop
            current
          end
        end

        # additonal notes by man power!
        addition = case repo
                   when :front
                     <<-'ADDITION'
  others:
ADDITION
                   when :back
                     <<-'ADDITION'
  others:
ADDITION
                   when :batch
                     <<-'ADDITION'
  others:
ADDITION
                   end
        f.puts addition
        f.puts ""
      end
    end
  end

  def self.run_command(command)
    puts "execute: #{command}"
    raise unless system(command)
  end
end

CreateReleaseNote.execute
