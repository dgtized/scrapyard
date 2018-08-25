#!/usr/bin/env ruby
# frozen_string_literal: true

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
    opts.banner = 'Usage: scrapyard.rb [command] [options]'
    opts.on(
      '-k', '--keys KEY1,KEY2', Array,
      'Specify keys for search or dumping in order of preference'
    ) do |keys|
      options[:keys] = keys
    end
    opts.on('-y', '--yard PATH', String,
            'The directory the scrapyard is stored in.') do |path|
      options[:yard] = path
    end
    opts.on('-p', '--paths PATH1,PATH2', Array,
            'Paths to store in the scrapyard') do |paths|
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
    store: 1,
    junk: 0,
    crush: 0
  }

  if args.empty?
    puts "No command specified from #{operations.keys}"
    puts opts
    exit
  end

  command = args.shift.intern
  options[:paths] += args # grab everything remaining after -- as a path

  if (remaining = operations[command])
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

  if %i[search store junk].include?(command) && options[:keys].empty?
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

  def self.to_path(yard, keys, suffix, log)
    keys.map { |k| yard.to_path + (Key.new(k).checksum!(log).to_s + suffix) }
  end
end

# Save or restores from a tarball
class Pack
  attr_reader :log
  def initialize(log)
    @log = log
  end

  def save(cache, paths)
    Tempfile.open('scrapyard') do |temp|
      temp_path = temp.path
      cmd = "tar czf %s %s" % [temp_path, paths.join(" ")]
      log.debug "Executing [#{cmd}]"
      system(cmd)
      FileUtils.mv temp_path, cache
      system("touch #{cache}")
    end

    log.info "Created: %s" % %x|ls -lah #{cache}|.chomp

    cache
  end

  def restore(cache, paths)
    cmd = "tar zxf #{cache}"
    log.debug "Found scrap in #{cache}"
    log.info "Executing [#{cmd}]"
    rval = system(cmd)
    unless paths.empty?
      log.info "Restored: %s" % %x|du -sh #{paths.join(" ")}|.chomp
    end
    rval == true ? 0 : 255
  end
end

# Yard Interface
class Yard
  def self.for(yard, log)
    klass = yard =~ /^s3:/ ? AwsS3Yard : FileYard
    @yard = klass.new(yard, log)
  end

  def to_path
    @log.error "not implemented"
  end

  def init
    @log.error "not implemented"
  end

  def search(key_paths)
    @log.error "not implemented"
  end

  def store(cache)
    @log.error "not implemented"
  end

  def junk(key_paths)
    @log.error "not implemented"
  end

  def crush
    @log.error "not_implemented"
  end
end

# Implement Yard using a directory as storage
class FileYard < Yard
  def initialize(yard, log)
    @path = Pathname.new(yard)
    @log = log
  end

  def to_path
    @path
  end

  def search(key_paths)
    init
    key_paths.each do |path|
      glob = Pathname.glob(path.to_s)
      @log.debug "Scanning %s -> %p" % [path,glob.map(&:to_s)]
      cache = glob.max_by(&:mtime)
      return cache if cache # return on first match
    end

    nil
  end

  def store(cache)
    init
    cache # no-op for local
  end

  def junk(key_paths)
    init
    key_paths.select(&:exist?).each(&:delete)
  end

  def crush
    init
    @log.info 'Crushing the yard to scrap!'
    @path.children.each do |tarball|
      if tarball.mtime < (Time.now - 20 * days)
        @log.info "Crushing: #{tarball}"
        tarball.delete
      else
        @log.debug "Keeping: #{tarball} at #{tarball.mtime}"
      end
    end
  end

  private

  def init
    if @path.exist?
      @log.info "Scrapyard: #{@path}"
    else
      @log.info "Scrapyard: #{@path} (creating)"
      @path.mkpath
    end
  end

  def days
    24 * 60 * 60
  end
end

# Implement Yard using an S3 bucket as storage
class AwsS3Yard < Yard
  def initialize(yard, log)
    @bucket = yard
    @log = log
  end

  def to_path
    '/tmp/'
  end

  def store(cache)
    remote_path = @bucket + Pathname.new(cache).basename.to_s
    system("aws s3 cp #{cache} #{remote_path}")
  end
end

class Scrapyard
  def initialize(yard, log)
    @yard = Yard.for(yard, log)
    @log = log
    @pack = Pack.new(@log)
  end

  attr_reader :log

  def search(keys, paths)
    log.info "Searching for #{keys}"
    key_paths = Key.to_path(@yard, keys, "*", log)

    if (cache = @yard.search(key_paths))
      exit(@pack.restore(cache, paths))
    else
      log.info 'Unable to find key(s): %p' % [paths.map(&:to_s)]
      exit 1
    end
  end

  def store(keys, paths)
    log.info "Storing #{keys}"
    key_path = Key.to_path(@yard, keys, ".tgz", log).first.to_s

    @yard.store(@pack.save(key_path, paths))
    exit 0
  end

  def junk(keys, _paths)
    log.info "Junking #{keys}"
    key_paths = Key.to_path(@yard, keys, ".tgz", log)
    log.debug "Paths: %p" % key_paths.map(&:to_s)
    @yard.junk(key_paths)
    exit 0
  end

  def crush(_keys, _paths)
    @yard.crush
    exit 0
  end
end

if $PROGRAM_NAME == __FILE__
  options = parse_options

  log = Logger.new(STDOUT)
  log.level = options[:verbose] ? Logger::DEBUG : Logger::WARN

  Scrapyard.new(options[:yard], log).send(
    options[:command], options[:keys], options[:paths]
  )
end
