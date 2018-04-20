#!/usr/bin/env ruby

require 'optparse'
require 'logger'
require 'pathname'

def parse_options(args = ARGV)
  options = {
    keys: [],
    yard: '/tmp/scrapyard'
  }

  parser = OptionParser.new(args) do |opts|
    opts.banner = "Usage: scrapyard.rb [command] [options]"
    opts.on('-k', '--keys KEY1,KEY2', Array,
            'Specify keys for search or dumping in order of preference') do |keys|
      options[:keys] = keys
    end
    opts.on('-y', '--yard PATH', String,
            'The directory the scrapyard is stored in.') do |path|
      options[:yard] = path
    end
    opts.on_tail('-v', '--verbose') do
      options[:verbose] = true
    end
    opts.on_tail('-h', '--help') do
      puts opts
      exit
    end
  end.parse!

  operations = {
    search: 1,
    dump: 1,
    junk: 0,
    crush: 0
  }

  if args.size == 0
    puts "No command specified from #{operations.keys}"
    puts opts
    exit
  end

  command = args.shift.intern

  if remaining = operations[command]
    if args.size >= remaining
      options[:command] = command
    else
      puts "#{command} requires paths"
      puts parser
      exit
    end
  else
    puts "Unrecognized command #{command}"
    puts parser
    exit
  end

  if %i{search dump junk}.include?(command) && options[:keys].empty?
    puts "Command #{command} requires at least one key argument"
  end

  options
end

class Scrapyard
  def initialize(yard, log)
    @yard = Pathname.new(yard).expand_path
    @log = log
  end

  attr_reader :log

  def search(keys)
    init
    log.info "Searching for #{keys}"
  end

  def dump(keys)
    init
    log.info "Dumping #{keys}"
  end

  def junk(keys)
    init
    log.info "Junking #{keys}"
  end

  def crush(_keys)
    init
    log.info "Crushing the yard to scrap!"
  end

  private

  def init
    if @yard.exist?
      @log.info "Scrapyard: #{@yard}"
    else
      @log.info "Scrapyard: #{@yard} (creating)"
      @yard.mkpath
    end
  end
end

options = parse_options

log = Logger.new(STDOUT)
log.level = if options[:verbose]
  Logger::DEBUG
else
  Logger::WARN
end

Scrapyard.new(options[:yard], log).send(options[:command], options[:keys])
