# frozen_string_literal: true

require 'fileutils'

module Scrapyard
  class Runner
    def initialize(yard, log)
      @yard = Scrapyard::Yard.for(yard, log)
      @log = log
      @pack = Scrapyard::Pack.new(@log)
    end

    attr_reader :log

    def initialize_paths(paths)
      log.info "Initializing paths %p" % [paths]
      FileUtils.rmtree paths
      FileUtils.mkdir_p paths
    end

    def search(keys, paths)
      log.info "Searching for %p" % [keys]
      key_paths = Scrapyard::Key.to_path(@yard, keys, "*", log)

      if (cache = @yard.search(key_paths))
        exit(@pack.restore(cache, paths))
      else
        log.info 'Unable to find key(s): %p' % [keys.map(&:to_s)]
        exit 1
      end
    end

    def store(keys, paths)
      log.info "Storing #{keys}"
      key_path = Scrapyard::Key.to_path(@yard, keys, ".tgz", log)

      # store accepts multiple keys but only uses the first, this ensures it's
      # easy to re-use values between search and store.
      @yard.store(@pack.save(key_path.first.to_s, paths))
      exit 0
    end

    def junk(keys, _paths)
      log.info "Junking #{keys}"
      key_paths = Scrapyard::Key.to_path(@yard, keys, ".tgz", log)
      log.debug "Paths: %p" % key_paths.map(&:to_s)
      @yard.junk(key_paths)
      exit 0
    end

    def crush(_keys, _paths)
      @yard.crush
      exit 0
    end
  end
end
