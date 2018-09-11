require_relative 'lib/scrapyard'

Gem::Specification.new do |s|
  s.name        = 'scrapyard'
  s.version     = ::Scrapyard::VERSION
  s.date        = '2018-09-11'
  s.summary     = 'A simple cache for faster CI builds'
  s.authors     = ['Charles L.G. Comstock', 'Hardy Jones']
  s.email       = ['dgtized@gmail.com']
  s.files       = Dir["**/*.rb"]
  s.homepage    = 'https://github.com/dgtized/scrapyard'
  s.license     = 'BSD-3-Clause'
end
