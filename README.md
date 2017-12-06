# Lolcommits Tumblr

[![Gem Version](https://img.shields.io/gem/v/lolcommits-tumblr.svg?style=flat)](http://rubygems.org/gems/lolcommits-tumblr)
[![Travis Build Status](https://travis-ci.org/lolcommits/lolcommits-tumblr.svg?branch=master)](https://travis-ci.org/lolcommits/lolcommits-tumblr)
[![Maintainability](https://img.shields.io/codeclimate/maintainability/lolcommits/lolcommits-tranzlate.svg)](https://codeclimate.com/github/lolcommits/lolcommits-tranzlate/maintainability)
[![Test Coverage](https://img.shields.io/codeclimate/c/lolcommits/lolcommits-tranzlate.svg)](https://codeclimate.com/github/lolcommits/lolcommits-tumblr/test_coverage)
[![Gem Dependency Status](https://gemnasium.com/badges/github.com/lolcommits/lolcommits-tumblr.svg)](https://gemnasium.com/github.com/lolcommits/lolcommits-tumblr)

[lolcommits](https://lolcommits.github.io/) takes a snapshot with your webcam
every time you git commit code, and archives a lolcat style image with it. Git
blame has never been so much fun!

This is a simple plugin to post lolcommits to your Tumblr. Configure it with a
Tumblr access token and secret (the plugin will guide you through this process).

## Requirements

* Ruby >= 2.0.0
* A webcam
* [ImageMagick](http://www.imagemagick.org)
* [ffmpeg](https://www.ffmpeg.org) (optional) for animated gif capturing
* A [Tumblr](https://tumblr.com) account

## Installation

After installing the lolcommits gem, install this plugin with:

    $ gem install lolcommits-tumblr

Then configure to enable. If this is your first time setting up, you'll be asked
to visit Tumblr to authenticate and allow access.

    $ lolcommits --config -p tumblr
    # set enabled to `true`
    # confirm access for this plugin at tumblr.com (link opens automatically)
    # click 'allow' then return to the console to set your Tumblr name
    # optionally set the plugin to auto-open each created Tumblr post

That's it! Your next lolcommit will automatically be posted to your Tumblr blog.
To disable use:

    $ lolcommits --config -p tumblr
    # and set enabled to `false`

## Development

Check out this repo and run `bin/setup`, this will install all dependencies and
generate docs. Use `bundle exec rake` to run all tests and generate a coverage
report.

You can also run `bin/console` for an interactive prompt that will allow you to
experiment with the gem code.

This plugin uses the [tumblr-client](https://github.com/tumblr/tumblr_client)
and [OAuth](https://rubygems.org/gems/oauth/versions/0.5.3) gems. A
[Webrick](https://rubygems.org/gems/webrick) server is started during
configuration, to provide a responding `return_uri` for the OAuth flow to
complete.

## Tests

MiniTest is used for testing. Run the test suite with:

    $ rake test

## Docs

Generate docs for this gem with:

    $ rake rdoc

## Troubles?

If you think something is broken or missing, please raise a new
[issue](https://github.com/lolcommits/lolcommits-tumblr/issues). Take
a moment to check it hasn't been raised in the past (and possibly closed).

## Contributing

Bug [reports](https://github.com/lolcommits/lolcommits-tumblr/issues) and [pull
requests](https://github.com/lolcommits/lolcommits-tumblr/pulls) are welcome on
GitHub.

When submitting pull requests, remember to add tests covering any new behaviour,
and ensure all tests are passing on [Travis
CI](https://travis-ci.org/lolcommits/lolcommits-tumblr). Read the
[contributing
guidelines](https://github.com/lolcommits/lolcommits-tumblr/blob/master/CONTRIBUTING.md)
for more details.

This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the [Contributor
Covenant](http://contributor-covenant.org) code of conduct. See
[here](https://github.com/lolcommits/lolcommits-tumblr/blob/master/CODE_OF_CONDUCT.md)
for more details.

## License

The gem is available as open source under the terms of
[LGPL-3](https://opensource.org/licenses/LGPL-3.0).

## Links

* [Travis CI](https://travis-ci.org/lolcommits/lolcommits-tumblr)
* [Code Climate](https://codeclimate.com/github/lolcommits/lolcommits-tumblr)
* [Test Coverage](https://codeclimate.com/github/lolcommits/lolcommits-tumblr/coverage)
* [RDoc](http://rdoc.info/projects/lolcommits/lolcommits-tumblr)
* [Issues](http://github.com/lolcommits/lolcommits-tumblr/issues)
* [Report a bug](http://github.com/lolcommits/lolcommits-tumblr/issues/new)
* [Gem](http://rubygems.org/gems/lolcommits-tumblr)
* [GitHub](https://github.com/lolcommits/lolcommits-tumblr)
