# -*- encoding: utf-8 -*-
require File.expand_path('../lib/redis_lock/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "redis_lock"
  gem.authors       = ["Mark Lanett", "Ravil Bayramgalin", "Jamie Cobbett", "Jonathan Hyman", "Alexander Lang", "Tom Mornini"]
  gem.email         = ["mark.lanett@gmail.com"]
  gem.description   = %q{Pessimistic locking using Redis}
  gem.summary       = %q{Pessimistic locking using Redis}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]
  gem.version       = RedisLock::VERSION

  gem.add_dependency "redis", "~> 3"

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'rb-fsevent'      # for guard
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'awesome_print'
end
