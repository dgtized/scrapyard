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
      Tempfile.open('scrapyard') do |temp|
        temp_path = temp.path
        execute("tar czf %s %s" % [temp_path, paths.join(" ")])
        FileUtils.mv temp_path, cache
        system("touch #{cache}")
      end

      log.info "Created: %s" % %x|ls -lah #{cache}|.chomp

      cache
    end

    def restore(cache, paths)
      log.debug "Found scrap in #{cache}"
      rval = execute("tar zxf #{cache}")
      unless paths.empty?
        log.info "Restored: %s" % %x|du -sh #{paths.join(" ")}|.chomp
      end
      rval == true ? 0 : 255
    end

    private

    def execute(cmd)
      rval = nil
      duration = Benchmark.realtime { rval = system(cmd) }
      log.debug "Executing[%s] (%.1f ms)" % [cmd, duration * 1000]
      rval
    end
  end
end
