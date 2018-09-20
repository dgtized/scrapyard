# frozen_string_literal: true

require 'benchmark'
require 'tempfile'
require 'fileutils'

module Scrapyard
  # Save or restores from a tarball
  class Pack
    attr_reader :log
    def initialize(log)
      @log = log
    end

    def save(cache, paths)
      temp = Tempfile.new('scrapyard')
      execute("tar czf %s %s" % [temp.path, paths.join(" ")])

      # removes temp & saves tarball to cache directory
      FileUtils.mv temp.path, cache

      # update mtime of cache so it is first on lookup
      FileUtils.touch cache

      contents = %x|ls -lah #{cache}|
      log.info "Created: %s" % contents.chomp

      cache
    end

    def restore(cache, paths)
      log.debug "Found scrap in #{cache}"
      rval = execute("tar zxf #{cache}")
      unless paths.empty?
        contents = %x|du -sh #{paths.join(" ")}|
        log.info "Restored: \n%s" % contents.chomp
      end
      rval == true ? 0 : 255
    end

    private

    def execute(cmd)
      rval = nil
      duration = Benchmark.realtime { rval = system(cmd) }
      log.info "Executing[%s] (%.1f ms)" % [cmd, duration * 1000]
      rval
    end
  end
end
