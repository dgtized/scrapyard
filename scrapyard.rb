#!/usr/bin/env ruby

require 'optparse'
require 'logger'
require 'pathname'
require 'digest'
require 'tempfile'
require 'fileutils'

def parse_options(args = ARGV)
  options = {
    keys: [],
    yard: '/tmp/scrapyard',
    paths: []
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
    opts.on("-p", '--paths PATH1,PATH2', Array,
            "Paths to store in the scrapyard") do |paths|
      options[:paths] = paths
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
  options[:paths] += args # grab everything remaining after -- as a path

  if remaining = operations[command]
    if options[:paths].size >= remaining
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

class Key
  def initialize(key)
    @key = key
  end

  def checksum!(log)
    @key = @key.gsub(/(#\([^}]+\))/) do |match|
      f = Pathname.new match[2..-2].strip
      if f.exist?
        log.debug "Including sha1 of #{f}"
        Digest::SHA1.file(f).hexdigest
      else
        log.debug "File #{f} does not exist, ignoring checksum"
        ''
      end
    end

    self
  end

  def to_s
    @key
  end

  def self.to_path(yard, keys, log)
    keys.map { |k| yard + (Key.new(k).checksum!(log).to_s + ".tgz") }
  end
end

class Scrapyard
  def initialize(yard, log)
    @yard = Pathname.new(yard).expand_path
    @log = log
  end

  attr_reader :log

  def search(keys, paths)
    init
    log.info "Searching for #{keys}"
    key_paths = Key.to_path(@yard, keys, log)
    cache = key_paths.select(&:exist?).max_by(&:mtime)
    if cache
      cmd = "tar zxf #{cache}"
      log.debug "Found scrap in #{cache}"
      log.info "Executing [#{cmd}]"
      rval = system(cmd)
      unless paths.empty?
        log.info "Restored: %s" % %x|du -sh #{paths.join(" ")}|.chomp
      end
      exit(rval == true ? 0 : 255)
    else
      log.debug "Unable to find scrap from any of %p" % [paths.map(&:to_s)]
      exit 1
    end
  end

  def dump(keys, paths)
    init
    log.info "Dumping #{keys}"
    key_paths = Key.to_path(@yard, keys, log).map(&:to_s)

    Tempfile.open('scrapyard') do |temp|
      temp_path = temp.path
      cmd = "tar czf %s %s" % [temp_path, paths.join(" ")]
      log.debug "Executing %p" % [cmd]
      system(cmd)

      key_paths.each do |key|
        FileUtils.cp(temp_path, key)
        system("touch #{key}")
      end
    end

    log.info "Created: %s" % %x|ls -lah #{key_paths.join(" ")}|.chomp
    exit 0
  end

  def junk(keys, _paths)
    init
    log.info "Junking #{keys}"
    key_paths = Key.to_path(@yard, keys, log)
    log.debug "Paths: %p" % key_paths.map(&:to_s)
    key_paths.select(&:exist?).each(&:delete)
    exit 0
  end

  def crush(_keys, _paths)
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

if $PROGRAM_NAME == __FILE__
  options = parse_options

  log = Logger.new(STDOUT)
  log.level = if options[:verbose]
    Logger::DEBUG
  else
    Logger::WARN
  end

  Scrapyard.new(options[:yard], log).send(
    options[:command], options[:keys], options[:paths]
  )
end
