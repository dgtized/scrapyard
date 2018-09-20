# frozen_string_literal: true

require 'pathname'
require 'benchmark'
require 'aws-sdk-s3'

module Scrapyard
  # Yard Interface
  # Derived classes should implement
  # #to_path
  # #search
  # #store
  # #junk
  # #crush
  class Yard
    def self.for(yard, log, aws_config)
      if yard =~ /^s3:/
        AwsS3Yard.new(yard, log, aws_config)
      else
        FileYard.new(yard, log)
      end
    end
  end

  # Implement Yard using a directory as storage
  class FileYard < Yard
    def initialize(yard, log)
      @path = Pathname.new(yard)
      @log = log
      init
    end

    def to_path
      @path
    end

    def search(keys)
      keys.each do |key|
        glob = Pathname.glob(key.local.to_s + "*")
        @log.debug "Scanning %s -> %p" % [key, glob.map(&:to_s)]
        cache = glob.max_by(&:mtime)
        return cache.basename.to_s if cache # return on first match
      end

      nil
    end

    def fetch(key); end

    def store(_key, cache)
      cache # no-op for local
    end

    def junk(keys)
      keys.map(&:local).select(&:exist?).each(&:delete)
    end

    def crush
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
    def initialize(yard, log, aws_config)
      require 'aws-sdk-s3'
      @yard_name = yard.sub(%r{^s3://}, '').sub(%r{/$}, '')
      @bucket = Aws::S3::Resource.new(aws_config).bucket(@yard_name)
      @log = log
    end

    def to_path
      Pathname.new('/tmp')
    end

    def search(keys)
      files = []
      duration = Benchmark.realtime do
        files = @bucket.objects.to_a
      end
      @log.info("Found %d objects in %s (%.1f ms)" %
                [files.count, @yard_name, duration * 1000])

      keys.each do |prefix|
        glob = files.select { |f| f.key.start_with?(prefix.to_s) }
        @log.debug "Scanning %s -> %p" % [prefix, glob.map(&:key)]
        needle = glob.max_by(&:last_modified)
        return needle.key if needle
      end

      nil
    end

    def fetch(key)
      duration = Benchmark.realtime do
        @bucket.object(key.to_s).get(response_target: key.local)
      end
      @log.info "Downloaded key %s (%.1f ms)" % [key, duration * 1000]
    end

    def store(key, cache)
      duration = Benchmark.realtime do
        @bucket.object(key).upload_file(cache)
      end
      @log.info "Uploaded key %s (%.1f ms)" % [key, duration * 1000]
    end

    def junk(keys)
      duration = Benchmark.realtime do
        @bucket.delete_objects(
          delete: { objects: keys.map { |k| { key: k.to_s }} }
        )
      end
      @log.info("Deleted %p (%.1f ms)" % [keys.map(&:to_s), duration * 1000])
    end

    def crush
      @log.error "Not Implemented: prefer s3 key expiration rules"
    end
  end
end
