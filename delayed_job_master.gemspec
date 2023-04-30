# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'delayed/master/version'

Gem::Specification.new do |spec|
  spec.name          = "delayed_job_master"
  spec.version       = Delayed::Master::VERSION
  spec.authors       = ["Yoshikazu Kaneta"]
  spec.email         = ["kaneta@sitebridge.co.jp"]
  spec.summary       = %q{A simple delayed_job master process to control multiple workers}
  spec.description   = %q{A simple delayed_job master process to control multiple workers}
  spec.homepage      = "https://github.com/kanety/delayed_job_master"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.7'

  spec.add_dependency "delayed_job", ">= 4.1"
  spec.add_dependency "get_process_mem"

  spec.add_development_dependency "rails", ">= 6.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "delayed_job_active_record", ">= 4.1"
end
