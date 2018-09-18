# frozen_string_literal: true

require 'pathname'
require 'digest'

module Scrapyard
  # Translates keys into legal names and handles checksum syntax
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

    def translate!(log)
      key = @key.gsub(/[^a-zA-Z0-9_\-\.]/, "!")
      log.debug "Translated key to %s" % key if key != @key
      @key = key
      self
    end

    def process!(log)
      checksum!(log).translate!(log)
      self
    end

    def to_s
      @key
    end

    def self.to_path(yard, keys, suffix, log)
      keys.map { |k| yard.to_path + (Key.new(k).process!(log).to_s + suffix) }
    end

    def self.to_keys(keys, suffix, log)
      keys.map { |k| Key.new(k).process!(log).to_s + suffix }
    end
  end
end
