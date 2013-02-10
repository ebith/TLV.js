#!/usr/bin/env ruby
# coding: utf-8
require 'time'
gem 'mongoid', '~> 2.0'
require 'mongoid'

Mongoid.configure do |config|
    config.master = Mongo::Connection.new('localhost', 27017).db("tiarra")
end

class Log
  include Mongoid::Document
  field :is_notice, :type => Boolean
  field :log
  field :nick
  field :channel
  field :timestamp, :type =>DateTime, :default => lambda{Time.now}
end

dir = ARGV[0]

sec = 0
_time = '1970/01/01 09:00:00'
Dir::foreach(dir) do |filename|
  next unless filename =~ /\.txt$/
  date = File::basename(filename, '.txt')
  open(dir + '/' + filename) do |file|
    file.each do |line|
      column = line.split
      time = column.shift

      if /^[()]/ =~ column[0]
        is_notice = true
      elsif /^[<>]/ =~ column[0]
        is_notice = false
      else
        next
      end

      if /^[()<>](#\S+@\S+):(\S+)[()<>]$/ =~ column.shift
        if Time.parse(time) == Time.parse(_time)
          sec += 1
        else
          sec = 0
        end

        log = Log.new(
          :is_notice => is_notice,
          :log => column.join(' '),
          :nick => $2,
          :channel => $1,
          :timestamp => Time.parse("#{date} #{time}:#{sec}")
        )

        log.save
        _time = time
      end
    end
  end
end

p 'All done.'
