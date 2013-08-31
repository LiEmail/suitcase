# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "suitcase/version"

Gem::Specification.new do |s|
  s.name        = "suitcase"
  s.version     = Suitcase::VERSION
  s.authors     = ["Walter Nelson"]
  s.email       = ["walter.john.nelson@gmail.com"]
  s.homepage    = "http://github.com/walternelson/suitcase"
  s.summary     = %q{Ruby gem for interacting with the EAN Hotel API.}
  s.description = %q{Suitcase is a complete library for interacting with the EAN (Expedia.com) Hotel API.}
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "minitest"
  s.add_development_dependency "chronic"
  s.add_development_dependency "rake"
  s.add_development_dependency "pry"

  s.add_runtime_dependency "json"
  s.add_runtime_dependency "patron"
end

