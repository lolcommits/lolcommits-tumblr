# ChangeLog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][KeepAChangelog] and this
project adheres to [Semantic Versioning][Semver].

## [Unreleased]

- Your contribution here!

## [0.5.1] - 2021-02-06
## Added
- Support for Ruby 3.0 (ditch tumblr_client gem, use faraday with simple_oauth)

## [0.5.0] - 2020-01-24
### Removed
- Support for Ruby < 2.4 (older rubies no longer supported)

## [0.4.1] - 2019-08-16
### Added
- allow erb captions, thanks to @xurizaemon

## [0.4.0] - 2019-05-20
### Changed
- lolcommits gem is a runtime dependency
- Use `lolcommit_path` (instead of `main_image`)
- Requires at least lolcommits >= `0.14.2`
- Updated README and gemspec

### Removed
- Support for lolcommits < `0.14.2`

## [0.3.0] - 2019-04-24
### Removed
- Support for Ruby < 2.3 (older rubies no longer supported)

### Added
- `frozen_string_literal: true` to all ruby files

## [0.2.0] - 2018-17-06
### Changed
- Require at least Ruby 2.3 (webrick requires it)

## [0.1.1] - 2018-05-24
### Changed
- Updated gemspec meta data links.

## [0.1.0] - 2018-03-27
### Changed
- Require at least lolcommits 0.12.0

### Removed
- Removed runner_order method

## [0.0.5] - 2018-02-05
### Changed
- Refactor plugin config for lolcommits
- Require at least lolcommits 0.10.0

### Removed
- Dropped support for Ruby 2.0

## [0.0.3] - 2017-12-09
### Changed
- Updated README
- Test fixed

## [0.0.2] - 2017-12-06
### Changed
- Removed vendored font file
- README

## [0.0.1] - 2017-10-14
### Changed
- Initial release

[Unreleased]: https://github.com/lolcommits/lolcommits-tumblr/compare/v0.5.1...HEAD
[0.5.1]: https://github.com/lolcommits/lolcommits-tumblr/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/lolcommits/lolcommits-tumblr/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/lolcommits/lolcommits-tumblr/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/lolcommits/lolcommits-tumblr/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/lolcommits/lolcommits-tumblr/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/lolcommits/lolcommits-tumblr/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/lolcommits/lolcommits-tumblr/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/lolcommits/lolcommits-tumblr/compare/v0.0.5...v0.1.0
[0.0.5]: https://github.com/lolcommits/lolcommits-tumblr/compare/v0.0.3...v0.0.5
[0.0.3]: https://github.com/lolcommits/lolcommits-tumblr/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/lolcommits/lolcommits-tumblr/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/lolcommits/lolcommits-tumblr/compare/8c8ec30...v0.0.1
[KeepAChangelog]: http://keepachangelog.com/en/1.0.0/
[Semver]: http://semver.org/spec/v2.0.0.html
