# frozen_string_literal: true

require 'pathname'
require 'digest'

module Scrapyard
  # Translates keys into legal names and handles checksum syntax
  class Key
    attr_reader :log
    def initialize(key, to_path, log)
      @log = log
      @to_path = to_path
      @key = translate(checksum(key))
    end

    def to_s
      @key
    end

    def local
      @to_path + @key
    end

    def self.to_path(yard, keys, suffix, log)
      keys.map do |k|
        yard.to_path + (Key.new(k, yard.to_path, log).to_s + suffix)
      end
    end

    def self.to_keys(keys, to_path, suffix, log)
      keys.map { |k| Key.new(k + suffix, to_path, log) }
    end

    private

    def checksum(key)
      key.gsub(/(#\([^}]+\))/) do |match|
        f = Pathname.new match[2..-2].strip
        if f.exist?
          log.debug "Including sha1 of #{f}"
          Digest::SHA1.file(f).hexdigest
        else
          log.warn "File #{f} does not exist, ignoring checksum"
          ''
        end
      end
    end

    def translate(key)
      translated = key.gsub(/[^a-zA-Z0-9_\-\.]/, "!")
      log.warn "Translated key to %s" % key if key != translated
      translated
    end
  end
end
