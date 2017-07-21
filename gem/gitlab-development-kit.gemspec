# coding: utf-8

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'gitlab-development-kit'

Gem::Specification.new do |spec|
  spec.name          = "gitlab-development-kit"
  spec.version       = GDK::GEM_VERSION
  spec.authors       = ["Jacob Vosmaer"]
  spec.email         = ["jacob@gitlab.com"]

  spec.summary       = %q(CLI for GitLab Development Kit)
  spec.description   = %q(CLI for GitLab Development Kit.)
  spec.homepage      = "https://gitlab.com/gitlab-org/gitlab-development-kit"
  spec.license       = "MIT"
  spec.files         = ['lib/gitlab-development-kit.rb']
  spec.executables   = ['gdk']
end
