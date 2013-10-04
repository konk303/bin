#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'active_support/all'
require 'pry'

# = apacheが出すlogをパース
module LogParserApache
  Log = Struct.new(
    :host,
    :remote_log,
    :user,
    :time,
    :time_spent,
    :request_method,
    :request_url,
    :http_version,
    :status,
    :bytes,
    :referer,
    :user_agent,
    :forwarded,
    :original_log
    )

  class << self
    def execute(input)
      unless input.file.is_a? File
        puts "no file given! aborting"
        return
      end

      @out = "#{Dir.home}/work/logs/result_a.txt"

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
      format = %r{^(\S+) (\S+) (.+) \[(.+)\] (\S+) "(\S+) (\S+) (\S+)" (\d{3}) (\S+) "(\S+)" "(.*)\\ "(\S*)"$}
      [].tap do |logs|
        input.each_line do |l|
          data = l.match(format).to_a.tap(&:shift)
          # `-` to nil
          data.map!{|c| c == "-" ? nil : c}
          # access time
          data[3] = parse_time(data[3])
          # to_i on time_spent
          data[4] = data[4].to_f / 1000000
          data << l
          logs << Log.new(*data)
        end
      end
    end

    # conditions/orders should be rewriten on demand
    def select_and_sort(logs)
      logs.
        # select{|l| l.sec.present? && l.sec > 10}.
        sort_by{|l| [l.time]}
        # reverse[0, 10]
    end

    def output(logs)
      File.open(@out, "w") do |f|
        logs.each do |l|
          # format should be rewriten on demand
          # f.puts "#{l.original_log}"
          f.puts "#{l.time} (#{l.time_spent}): #{l.request_method} #{l.request_url}"
        end
      end
    end

    def parse_time(apache_time_string)
      mm = apache_time_string.match %r{^(\d+)/([a-zA-Z]+)/(\d+):([\d:]+) ([+-]\d+)}
      Time.parse("#{mm[1]} #{mm[2]} #{mm[3]} #{mm[4]} #{mm[5]}")
    end
  end
end

LogParserApache.execute(ARGF)
