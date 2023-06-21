lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "lolcommits/tumblr/version"

Gem::Specification.new do |spec|
  spec.name     = "lolcommits-tumblr"
  spec.version  = Lolcommits::Tumblr::VERSION
  spec.authors  = ["Matthew Hutchinson"]
  spec.email    = ["matt@hiddenloop.com"]
  spec.summary  = %q{Post lolcommits to Tumblr}
  spec.homepage = "https://github.com/lolcommits/lolcommits-tumblr"
  spec.license  = "LGPL-3.0"

  spec.description = <<-DESC
  A simple plugin to post lolcommits to your Tumblr. Configure it with a
  Tumblr access token and secret.
  DESC

  spec.metadata = {
    "homepage_uri"      => "https://github.com/lolcommits/lolcommits-tumblr",
    "changelog_uri"     => "https://github.com/lolcommits/lolcommits-tumblr/blob/master/CHANGELOG.md",
    "source_code_uri"   => "https://github.com/lolcommits/lolcommits-tumblr",
    "bug_tracker_uri"   => "https://github.com/lolcommits/lolcommits-tumblr/issues",
    "allowed_push_host" => "https://rubygems.org"
  }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(assets|test|features)/}) }
  spec.test_files    = `git ls-files -- {test,features}/*`.split("\n")
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.4"

  spec.add_runtime_dependency "lolcommits", ">= 0.14.2"
  spec.add_runtime_dependency("faraday", '2.7.7')
  spec.add_runtime_dependency("faraday_middleware")
  spec.add_runtime_dependency("simple_oauth")
  spec.add_runtime_dependency("oauth")
  spec.add_runtime_dependency("webrick")

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "simplecov"
end
