#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pry'

# = merge commitのログからnoteを作成
# （可能ならrelease branchを触る時に入れ込みたい）
module CreateReleaseNote
  def self.initialize
    @wd = "#{Dir.home}/tmp/git"
    @out = "#{Dir.home}/work/release_note.txt"
    @release_tag_prefix = "CT_VER"
    @deploy_tag_prefix = "CT_DEPLOY"
    @feature_branch_prefix = "f/"
    @hotfix_branch_prefix = "h/"
    @release_branch = "release"
    @develop_branch = "develop"
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

        f.puts "#{repo}:\n"

        # fetch
        run_command("cd #{d} && git fetch")

        tags = `cd #{d} && git tag -l`.split("\n")
        release_tags = tags.grep(/^#{@release_tag_prefix}/).sort.reverse.
          unshift("HEAD").push("C_201305151645")
        deploy_tags = tags.grep(/^#{@deploy_tag_prefix}/).sort.reverse.
          unshift("HEAD").push("C_201305151645")
        log_command = "cd #{d} && git log --oneline --merges"

        # release note for release per deploy (/h merges on prev_tag..current_tag)
        if deploy_tags.any?
          # co release
          run_command("cd #{d} && git checkout release")
          # update release
          run_command("cd #{d} && git merge origin/release")

          f.puts "  release merges:\n"
          deploy_tags.reduce do |prev, current|
            deploy_commits = "#{current}..#{prev}"
            deploy_merges = `#{log_command} #{deploy_commits}`.split("\n").
              grep(/Merge branch '#{@hotfix_branch_prefix}(.*?)' into release/).
              map{|commit|
              commit.sub(/.*Merge branch '#{@hotfix_branch_prefix}(.*?)' into release/){$1}}.
              sort.uniq
            next current unless deploy_merges.any?
            f.puts "    #{prev}:\n"
            deploy_merges.each {|commit| f.puts "      #{commit}"}
            current
          end
        end

        # release note for develop per release (/f merges on prev_tag..current_tag)
        if release_tags.any?
          # co develop
          run_command("cd #{d} && git checkout develop")
          # update develop
          run_command("cd #{d} && git merge origin/develop")

          f.puts "  develop merges:\n"
          release_tags.reduce do |prev, current|
            develop_commits = "#{current}..#{prev}"
            develop_merges = `#{log_command} #{develop_commits}`.split("\n").
              grep(/Merge branch '#{@feature_branch_prefix}(.*?)' into develop/).
              map{|commit|
              commit.sub(/.*Merge branch '#{@feature_branch_prefix}(.*?)' into develop/){$1}}.
              sort.uniq
            next current unless develop_merges.any?
            f.puts "    #{prev}:\n"
            develop_merges.each {|commit| f.puts "      #{commit}"}
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
                     ""
                   when :batch
                     ""
                   end
        f.puts addition
        f.puts "\n"
      end
    end
  end

  def self.run_command(command)
    puts "execute: #{command}"
    raise unless system(command)
  end
end

CreateReleaseNote.execute
