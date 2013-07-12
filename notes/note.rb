#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pry'
require 'active_support/core_ext'

# = merge commitのログからnoteを作成
# （可能ならrelease branchを触る時に入れ込みたい）
module CreateReleaseNote
  Env = Struct.new :name, :release_branch, :tag_regexp, :priority_branch_prefix, :tags

  class << self
    def execute(env)
      @wd = "#{Dir.home}/tmp/git"
      targets = parse_argv(env)
      out = "#{Dir.home}/work/release_note.txt"

      @repos = [:front, :back, :batch, :lws_framework]
      update_repos targets

      File.open(out, "w") do |f|
        targets.each do |target|
          f.puts "#{target.name}:"
          write_out_note target, f
        end
      end
      puts "wrote result to #{out}"
      puts "finished"
    end

    private

    def parse_argv(env)
      targets = []
      # CT
      unless ["st", "ST"].include? env
        targets << Env.new("CT releases", "release", %r{^CT_DEPLOY}, "CT")
      end
      # ST
      unless ["ct", "CT"].include? env
        targets << Env.new("ST releases", "develop", %r{^ST_DEPLOY}, "ST")
      end
      # develop
      unless ["ct", "CT", "st", "ST"].include? env
        targets << Env.new("versions", "develop", %r{^CT_VER})
      end
      targets
    end

    def update_repos(targets)
      @repos.each do |repo|
        initial_tag = repo == :lws_framework ? "1.0.9" : "C_201305151645"
        d = File.expand_path(repo.to_s, @wd)
        # fetch
        run_command("cd #{d} && git fetch --prune")
        tags = `cd #{d} && git tag -l`.split("\n")
        targets.each do |target|
          target.tags ||= {}
          target.tags[repo] = tags.grep(target.tag_regexp).sort.reverse.
            unshift("HEAD").push(initial_tag).take(10)
        end
      end
    end

    def write_out_note(target, file)
      branch_regexp = %r{Merge branch 'h/.*?' into #{target.release_branch}|Merge branch 'f/.*?' into develop}
      @repos.each do |repo|
        file.puts "  #{repo}:"
        d = File.expand_path(repo.to_s, @wd)
        log_command = "cd #{d} && git log --oneline --merges"

        target.tags[repo].reduce do |prev, current|
          range_command = "#{current}..#{prev}"
          merges = `#{log_command} #{range_command}`.split("\n").
            grep(branch_regexp){|commit| commit.sub(%r{.*Merge branch '[fh]/(.*?)'.*}){$1}}.
            sort.uniq
          priorities = merges.select{|merge| target.priority_branch_prefix && merge =~ /^#{target.priority_branch_prefix}/}
          others = merges - priorities
          file.puts "    #{prev.sub(target.tag_regexp, "")}:"
          priorities.each {|commit| file.puts "      #{commit}"}
          texts = others.in_groups_of(7, false).map{|grouped|
                "        #{grouped.join(", ")},"
          }.join("\n")
          file.puts texts.chop

          current
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
                   when :lws_framework
                     <<-'ADDITION'
  others:
ADDITION
                   end
        file.puts addition
        file.puts ""
      end
    end

    def run_command(command)
      puts "execute: #{command}"
      raise unless system(command)
    end
  end
end

CreateReleaseNote.execute(ARGV.first)
