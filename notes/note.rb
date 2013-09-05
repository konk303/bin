#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pry'

# = merge commitのログからnoteを作成
# == 概要
# 引数から設定したtargetsそれぞれに対し、対象release_branch内の該当リリースタグ間にマージされた
# 作業ブランチの一覧を出力する
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

    # == 引数から出力対象を決定する
    # === 概要
    # 配列targetsに構造体Envのインスタンスをしまう
    # === Envの引数:
    #  # name: 名前(タイトル欄のみに使用)
    #  # release_branch: 差分取得対象ブランチ (develop/master/etc)
    #  # tag_regexp: リリースタグ取得正規表現
    #  # priority_branch_prefix: (オプション) 優先表示(1行に1ブランチ表示)するブランチのprefix
    def parse_argv(env)
      targets = []
      # CT
      if ["ct", "CT"].include? env
        targets << Env.new("CT releases", "develop", %r{^CT_DEPLOY})
      end
      # ST
      if ["st", "ST"].include? env
        targets << Env.new("ST releases", "develop", %r{^ST_DEPLOY}, "ST")
      end
      # CTIT
      if ["ctit", "CTIT"].include? env
        targets << Env.new("CTIT releases", "master", %r{^CTIT_DEPLOY})
      end
      # OT
      if ["ot", "OT"].include? env
        targets << Env.new("OT releases", "master", %r{^OT_DEPLOY}, "OT")
      end
      # else (develop) - 引数省略時
      if targets.empty?
        targets << Env.new("OT releases", "master", %r{^OT_DEPLOY}, "OT")
        targets << Env.new("ST releases", "develop", %r{^ST_DEPLOY}, "ST")
        targets << Env.new("CT releases", "develop", %r{^CT_DEPLOY})
        # targets << Env.new("CTIT releases", "master", %r{^CTIT_DEPLOY})
        targets << Env.new("versions", "develop", %r{^CT_VER|^ST_VER})
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
      branch_regexp = if target.release_branch == "master"
                        %r{Merge branch 'h/.*?'$}
                      else
                        %r{Merge branch '[fh]/.*?' into #{target.release_branch}}
                      end
      @repos.each do |repo|
        file.puts "  #{repo}:"
        d = directory(repo)
        log_command = "cd #{d} && git log --oneline --merges"

        target.tags[repo].reduce("origin/#{target.release_branch}") do |newer, current|
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
