#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'net/telnet'
# require 'pry'

module MemcachedCleaner
  HOSTS = ["hoge", "localhost"]
  PORT = "11211"
  TIMEOUT = 10

  class << self
    def clean
      HOSTS.each do |host|
        begin
          puts "sending `flush_all` to #{host}:#{PORT}"
          client = Net::Telnet.new("Host" => host, "Port" => PORT, "Timeout" => TIMEOUT)
          puts "> flushed!" if client.cmd("String" => "flush_all", "Match" => /^OK/)
        rescue Timeout::Error
          puts "> no response"
        rescue
          puts "> connection failed"
        end
      end
    end
  end
end

MemcachedCleaner.clean
