# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'gitlab_development_kit'

Gem::Specification.new do |spec|
  spec.name          = 'gitlab-development-kit'
  spec.version       = GDK::GEM_VERSION
  spec.authors       = ['Jacob Vosmaer']
  spec.email         = ['jacob@gitlab.com']

  spec.summary       = 'CLI for GitLab Development Kit'
  spec.description   = 'CLI for GitLab Development Kit.'
  spec.homepage      = 'https://gitlab.com/gitlab-org/gitlab-development-kit'
  spec.license       = 'MIT'
  spec.files         = ['lib/gitlab_development_kit.rb']
  spec.executables   = ['gdk']

  spec.required_ruby_version = '~> 2.6.5'
end
