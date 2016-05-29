# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'danger-proselint.rb'

Gem::Specification.new do |spec|
  spec.name          = 'danger-proselint'
  spec.version       = DangerProselint::VERSION
  spec.authors       = ['David Grandinetti', 'Orta Therox']
  spec.email         = ['dbgrandi@gmail.com', 'orta.therox@gmail.com']
  spec.description   = %q{A danger plugin to lint a PR with proselint.}
  spec.summary       = %q{A danger plugin to lint a PR with proselint}
  spec.homepage      = 'https://github.com/dbgrandi/danger-proselint'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'danger'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
