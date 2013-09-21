#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'net/telnet'
require 'pry'

module MemcachedCleaner
  HOST = "localhost"
  PORT = "11211"
  TIMEOUT = 10

  class << self
    def clean
      begin
        puts "sending `flush_all` to #{HOST}:#{PORT}"
        client = Net::Telnet.new("Host" => HOST, "Port" => PORT, "Timeout" => 10)
        puts "flushed!" if client.cmd("String" => "flush_all", "Match" => /^OK/)
      rescue Errno::ECONNREFUSED
        puts "connection failed"
      rescue Timeout::Error
        puts "no response"
      end
    end
  end
end

MemcachedCleaner.clean
