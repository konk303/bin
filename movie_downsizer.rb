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
  AUDIO_BITRATE = 32            # kbps

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

    attr_accessor :file, :resized_file, :movie

    def initialize(_file)
      @file = Pathname.new _file
      @resized_file = file.dirname.join "#{file.basename ".*"}#{RESIZED_FILE_SUFFIX}#{file.extname}"
    end

    def needs_converting?
      !resized_file.exist? && file.size > FILESIZE_BOUND
    end

    def convert!
      @movie = FFMPEG::Movie.new(file)
      puts "resizing #{file} to #{resized_file}!"
      puts '---'
      begin
        puts movie.inspect
        puts '---'
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

    # TODO: more precise options
    # FIXME: lower audio?
    # FIXME: rotation?
    def options
      {
        # audio_sample_rate: 44100,
        # audio_channels: 2,
        audio_bitrate: AUDIO_BITRATE,
        video_max_bitrate: new_bitrate,
        buffer_size: new_bitrate,
        # video_bitrate: new_bitrate,
        # FIXME: `-fs` doesn't work as inteded. it just stops encoding when file got bigger.
        # http://ffmpeg.gusari.org/viewtopic.php?f=11&t=2141
       # custom: "-fs #{FILESIZE_BOUND}"
      }
    end

    # desired bitrate, in kilobit/s
    # see https://trac.ffmpeg.org/wiki/Encode/H.264#twopass
    def new_bitrate
      accepted_total_bitrate = ((FILESIZE_BOUND * 8 / movie.duration) / 1024).to_i
      # 90% to be safe
      ((accepted_total_bitrate - AUDIO_BITRATE) * 0.9).to_i
    end
  end
end

FFMPEG::Transcoder.timeout = false

target_dir = ARGV.presence || [Pathname.new(Dir.home).join("doc").to_s]
target_dir.each do |dir|
  MovieDownSizer.new(dir).convert_all!
end
