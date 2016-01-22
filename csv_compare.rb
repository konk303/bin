#!/usr/bin/env ruby

require 'pry'
require 'active_support/all'
require 'nkf'
require 'csv'
require 'diffy'

Diffy::Diff.default_format = :html
Diffy::Diff.default_options.merge!(
  source: 'files',
  include_plus_and_minus_in_html: true,
  context: 1,
)

module ToComparable
  class << self
    def execute
      puts "starting"
      @dir = File.expand_path(File.dirname(__FILE__))
      globs = if ARGV.present?
                ARGV.map{ |input| File.join(@dir, "new_original", input) }
                # ARGV.map{ |input| File.join(@dir, "old_original", input) }
                else
                Dir.glob File.join(@dir, "new_original", '*.csv')
                # Dir.glob File.join(@dir, "old_original", '*.csv')
              end
      puts "target: #{globs.size} files"
      globs.each do |file|
        original_content = File.read(file)
        new_content = each_columns_to_lines(convert_to_utf8(original_content))
        new_file = file.sub(/new_original/, 'new')
        # new_file = file.sub(/old_original/, 'old')
        if new_content != original_content
          write(new_file, new_content)
        end
        create_diff_html(new_file, new_content)
      end
      create_index_html
    end

    def convert_to_utf8(content)
      enc = NKF.guess(content)
      if enc == Encoding::UTF_8
        content
      else
        content.force_encoding(enc).encode('utf-8', undef: :replace)
      end
    end

    def each_columns_to_lines(utf8_content)
      if utf8_content.start_with?('L0000(proc')
        utf8_content
      else
        csv = CSV.parse(utf8_content)
        csv[1, 10000000].sort_by{ |l| l.try(:[], 0) }.unshift(csv[0])
          .each.with_index.each_with_object([]){ |(l, i), a|
          process_id = l.try(:[], 0)
          a << l.map.with_index{ |c, ii| "L#{"%04d" % i}(proc:#{process_id}):C#{"%04d" % ii}:#{c}" }
        }.flatten.join("\n")
      end
    end

    def write(file, content)
      puts "  rewriting  #{file}"
      File.write(file, content)
    end

    def create_diff_html(file, content)
      old_file = File.join(@dir, "old", File.basename(file))
      diff = Diffy::Diff.new(old_file, file)
      # return if diff.to_s == "<div class=\"diff\"></div>"
      diff_html = File.join(@dir, "html", "#{File.basename(file)}.diff.html")
      puts "  creating diff html #{diff_html}"
      File.open(diff_html, 'w') do |f|
        f.puts <<-"HTML"
<!DOCTYPE html>
<html lang='ja'>
  <head>
    <title>Diff results: #{File.basename(file)}</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <style type="text/css">#{Diffy::CSS}</style>
  </head>
  <body>
  <h1>Diff results: #{File.basename(file)}</h1>
#{diff.to_s}
  </body>
</html>
          HTML
      end
    end

    def create_index_html
      index_html_file = File.join(@dir, "html", "index.html")
      index_html = <<-HTML
<!DOCTYPE html>
<html lang='ja'>
  <head>
    <title>Diff results</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  </head>
  <body>
    <h1>Diff results</h1>
    <h2><a href="https://docs.google.com/a/r-n-i.jp/spreadsheets/d/12klIAfcYsPVzr8tIFtIDR0uwA-0msUXz8JYMeKooKFU/edit?usp=sharing">管理スプレッドシート (google doc)</a></h2>
    <ol>
      HTML

      Dir.glob(File.join(@dir, "html", "*.html")).each do |file|
        basename = File.basename(file)
        next if basename == 'index.html'
        index_html << "      <li><a href='./#{basename}'>#{basename}</a></li>\n"
      end

      index_html << <<-HTML
    </ol>
  </body>
  </html>
      HTML

      File.write(index_html_file, index_html)
    end
  end
end

ToComparable.execute
