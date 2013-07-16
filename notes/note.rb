#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pry'

# = merge commitのログからnoteを作成
# （可能ならrelease branchを触る時に入れ込みたい）
module CreateReleaseNote
  Env = Struct.new :name, :release_branch, :tag_regexp, :priority_branch_prefix, :tags

  class << self
    def execute(env)
      @wd = "#{Dir.home}/tmp/git"
      out = "#{Dir.home}/work/release_note.txt"
      targets = parse_argv(env)

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
        d = directory(repo)
        # fetch
        run_command("cd #{d} && git fetch --prune")
        tags = `cd #{d} && git tag -l`.split("\n")
        targets.each do |target|
          target.tags ||= {}
          target.tags[repo] = tags.grep(target.tag_regexp).sort.reverse.take(10)
        end
      end
    end

    def write_out_note(target, file)
      branch_regexp = %r{Merge branch 'h/.*?' into #{target.release_branch}|Merge branch 'f/.*?' into develop}
      @repos.each do |repo|
        file.puts "  #{repo}:"
        d = directory(repo)
        log_command = "cd #{d} && git log --oneline --merges"

        target.tags[repo].reduce("HEAD") do |newer, current|
          range = "#{current}..#{newer}"
          merges = `#{log_command} #{range}`.split("\n").
            grep(branch_regexp){|commit| commit.sub(%r{.*Merge branch '[fh]/(.*?)'.*}){$1}}.
            uniq.sort
          priorities, others = merges.partition{|merge| target.priority_branch_prefix && merge =~ /^#{target.priority_branch_prefix}/}
          file.puts "    #{newer.sub(target.tag_regexp, "")}:"
          priorities.each {|commit| file.puts "      #{commit}"}
          texts = others.each_slice(7).map{|grouped|
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

    def directory(repo)
      File.expand_path(repo.to_s, @wd)
    end
  end
end

CreateReleaseNote.execute(ARGV.first)
