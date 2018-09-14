require_relative 'lib/scrapyard'

Gem::Specification.new do |s|
  s.name        = 'scrapyard'
  s.version     = ::Scrapyard::VERSION
  s.date        = '2018-09-11'
  s.summary     = 'A simple cache for faster CI builds'
  s.authors     = ['Charles L.G. Comstock', 'Hardy Jones']
  s.email       = ['dgtized@gmail.com']
  s.homepage    = 'https://github.com/dgtized/scrapyard'
  s.license     = 'BSD-3-Clause'

  s.files       = Dir["**/*.rb"] + ["bin/scrapyard"]
  s.bindir      = "bin"
  s.executables = "scrapyard"
  s.require_paths = ["lib"]

  s.add_dependency('aws-sdk-s3', '~> 1')

  s.add_development_dependency('rspec', '~> 3')
  s.add_development_dependency('rspec_junit_formatter', '~> 0.4')
  s.add_development_dependency('rubocop', '~> 0')
end
