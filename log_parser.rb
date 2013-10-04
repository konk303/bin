#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'active_support/all'
require 'pry'

# = log4rが出すlogをパース
module LogParser
  Log = Struct.new(
    :time,
    :host_name,
    :pid,
    :thread_id,
    :session_id,
    :login_id,
    :classfication,
    :function_id,
    :level,
    :message,
    :message_id,
    :real_message,
    :sec,
    :original_log
    )

  class << self
    def execute(input)
      unless input.file.is_a? File
        puts "no file given! aborting"
        return
      end

      @out = "#{Dir.home}/work/logs/result.txt"

      puts "parsing"
      logs = parse(input)
      puts "finished parsing #{input}"
      result = select_and_sort(logs)
      puts "finished selecting and sorting"
      output(result)
      puts "wrote result to #{@out}"
      # extra mining by hand if needed
      binding.pry
      puts "finished"
    end

    private

    def parse(input)
      format = %r{\A(.+),\[(\S+)\],\[(\S+)\],\[(\S+)\],\[(\S+)\],\[(\S+)\],\[(\S+)\],\[(\S+)\],\[(\S+)\],(.*)\Z}
      [].tap do |logs|
        input.each_line do |l|
          data = l.match(format).to_a.tap(&:shift)
          if data.size == 10
            data[0] = Time.parse(data[0])   # :time
            data << (data[9] =~ %r{\A\[(.*?)\]:} ? $1 : "") # message_id
            data << data[9].sub(%r{\A\[.*?\]:}, "").sub(%r{\(.*? sec\)\Z}, "") # real message
            data << (data[9] =~ %r{\((.*?) sec\)\Z} ? $1.to_f : nil) # sec
            data << l
            logs << Log.new(*data)
          else
            logs.last.message << l
            logs.last.real_message << l
            logs.last.original_log << l
          end
        end
      end
    end

    # conditions/orders should be rewriten on demand
    def select_and_sort(logs)
      logs.
        select{|l| l.sec.present? && l.sec > 10}
        # select{|l| l.time > Time.parse("2013-10-01 14:01:00 +0900") && l.time < Time.parse("2013-10-01 14:01:59 +0900")}.
        # select{|l| l.login_id == "776"}.
        # select{|l| l.function_id =~ %r{contents_files#show}}.
        # sort_by{|l| [l.login_id, l.time, l.pid]}
    end

    def output(logs)
      File.open(@out, "w") do |f|
        logs.reduce(Log.new) do |prev, l|
          # if l.pid == prev.pid && l.function_id == l.function_id && (l.time - prev.time < 1)
          #   f.puts "                            - #{l.real_message.split("\n").first[0,40]}..."

          # else
          #   f.puts "#{l.time}: #{l.function_id} - #{l.real_message.split("\n").first[0,40]}..."
          # end
          # l
        end
        logs.each do |l|
          # format should be rewriten on demand
          f.puts "> #{l.time} - #{l.sec}: #{l.function_id}"
          f.puts l.real_message
          f.puts "=="
          # f.puts "#{l.login_id}:#{l.time} - #{l.function_id}(#{l.pid}) #{l.real_message}"
        end
      end
    end
  end
end

LogParser.execute(ARGF)
