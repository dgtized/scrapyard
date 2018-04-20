#!/usr/bin/env ruby

require 'optparse'

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

parse_options
