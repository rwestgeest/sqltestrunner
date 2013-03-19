# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sqltestrunner/version'

Gem::Specification.new do |gem|
  gem.name          = "sqltestrunner"
  gem.version       = Sqltestrunner::VERSION
  gem.authors       = ["Rob Westgeest"]
  gem.email         = ["rob@qwan.it"]
  gem.description   = %q{runs sqltests for CBS Testing environment}
  gem.summary       = %q{aqltestrunner takes a _sqlt.rb file and runs the content as test

  Specifically it runs blocks of testcases ordered by 'stand' blocks.

}
  gem.homepage      = "--none--"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'sqlite3'
end
