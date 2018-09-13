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
end
