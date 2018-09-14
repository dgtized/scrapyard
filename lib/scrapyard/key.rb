require 'pathname'
require 'digest'

module Scrapyard
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
end
