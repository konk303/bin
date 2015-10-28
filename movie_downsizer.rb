#!/usr/bin/env ruby

# glob movie files in directory, create downsized versions.

require 'active_support'
require 'active_support/core_ext'
require 'streamio-ffmpeg'
require 'pry'


class MovieDownSizer

  EXTS = %w(avi wmv mov 3gp mp4 ts mpg mpeg mp4v m4v 3gp2 3gpp 3gs mts mp4 m2ts swf).freeze
  FILESIZE_BOUND = (300 * 1024 * 1024).freeze # 300MB
  RESIZED_FILE_SUFFIX = '_resized'.freeze

  attr_accessor :dir

  def initialize(dir)
    @dir = Pathname.new dir
  end

  def convert_all!
    # exts_for_glob = (EXTS + EXTS.map(&:upcase)).join(",")
    Dir.glob(dir.join("**/*.{#{EXTS.join ","}}")).each do |f|
      file = EachFile.new f
      file.convert! if file.needs_converting?
    end
  end

  class EachFile

    attr_accessor :file, :resized_file

    def initialize(_file)
      @file = Pathname.new _file
      @resized_file = file.dirname.join "#{file.basename ".*"}#{RESIZED_FILE_SUFFIX}#{file.extname}"
    end

    def needs_converting?
      !this_is_resized_file? && !resized_file.exist? && file.size > FILESIZE_BOUND
    end

    def convert!
      puts "resizing #{file} to #{resized_file}!"
      puts '---'
      begin
        movie = FFMPEG::Movie.new(file)
        puts movie.inspect
        puts '---'
        # TODO: more precise options
        # FIXME: lower audio?
        # FIXME: rotation?
        options = {
          audio_sample_rate: 44100,
          audio_channels: 2,
          custom: "-fs #{FILESIZE_BOUND}"
        }

        movie.transcode(resized_file, options) { |progress| puts progress }
        resized_file.chmod 0774
        puts '---'
        puts "done"
      rescue => e
        puts '---'
        puts "ERROR #{e}"
      end
    end

    private

    def this_is_resized_file?
      file.basename('.*').to_s.end_with? RESIZED_FILE_SUFFIX
    end
  end
end

FFMPEG::Transcoder.timeout = false

target_dir = ARGV.presence || [Pathname.new(Dir.home).join("doc").to_s]
target_dir.each do |dir|
  MovieDownSizer.new(dir).convert_all!
end
