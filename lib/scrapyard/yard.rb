require 'pathname'
require 'benchmark'

module Scrapyard
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
      init
    end

    def to_path
      @path
    end

    def search(key_paths)
      key_paths.each do |path|
        glob = Pathname.glob(path.to_s)
        @log.debug "Scanning %s -> %p" % [path,glob.map(&:to_s)]
        cache = glob.max_by(&:mtime)
        return cache if cache # return on first match
      end

      nil
    end

    def store(cache)
      cache # no-op for local
    end

    def junk(key_paths)
      key_paths.select(&:exist?).each(&:delete)
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
    def initialize(yard, log)
      require 'aws-sdk-s3'
      yard_name = yard.sub(%r{^s3://}, '').sub(%r{/$}, '')
      # use $AWS_DEFAULT_REGION to specify region for now
      @bucket = Aws::S3::Resource.new.bucket(yard_name)
      @log = log
    end

    def to_path
      '/tmp/'
    end

    def search(key_paths)
      files = @bucket.objects

      key_paths.each do |key|
        prefix = Pathname.new(key).basename.to_s.tr('*', '')
        glob = files.select { |f| f.key.start_with?(prefix) }
        @log.debug "Scanning %s -> %p" % [prefix, glob.map(&:key)]
        needle = glob.max_by(&:last_modified)
        return fetch(needle.key) if needle
      end

      nil
    end

    def fetch(cache)
      local = Pathname.new(to_path).join(cache)
      duration = Benchmark.realtime do
        @bucket.object(cache).get(response_target: local)
      end
      @log.info "Downloaded key %s" % [cache, duration]
      local
    end

    def store(cache)
      key = Pathname.new(cache).basename.to_s
      duration = Benchmark.realtime do
        @bucket.object(key).upload_file(cache)
      end
      @log.info "Uploaded key %s (%.1f ms)" % [key, duration]
    end

    def junk(key_paths)
      keys = key_paths.map { |x| File.basename(x) }
      @log.info "Deleting %p" % keys
      @bucket.delete_objects(delete: { objects: keys.map { |k| { key: k }} })
    end
  end
end
