require 'lolcommits/plugin/base'
require 'oauth'
require 'webrick'
require 'cgi'
require 'tumblr_client'

module Lolcommits
  module Plugin
    class LolTumblr < Base

      TUMBLR_API_ENDPOINT    = 'https://www.tumblr.com'.freeze
      TUMBLR_CONSUMER_KEY    = '2FtMEDpEPkxjoUdkpHh42h9wqTu9IVS7Ra0QyNZGixdCvhllN2'.freeze
      TUMBLR_CONSUMER_SECRET = 'qWuvxgFUR2YyWKtbWOkDTMAiBEbj7ZGaNLaNQPba0PI1N4JpBs'.freeze

      ##
      # Returns the name of the plugin to identify the plugin to lolcommits.
      #
      # @return [String] the plugin name
      #
      def self.name
        'tumblr'
      end

      ##
      # Returns position(s) of when this plugin should run during the capture
      # process. Uploading happens when a new capture is ready.
      #
      # @return [Array] the position(s) (:capture_ready)
      #
      def self.runner_order
        [:capture_ready]
      end

      ##
      # Post-capture hook, runs after lolcommits captures a snapshot. Uploads
      # the lolcommit image to the remote server with an optional Authorization
      # header and the following request params.
      #
      # `file`    - captured lolcommit image file
      # `message` - the commit message
      # `repo`    - repository name e.g. mroth/lolcommits
      # `sha`     - commit SHA
      # `key`     - key (string) from plugin configuration (optional)
      # `author_name` - the commit author name
      # `author_email` - the commit author email address
      #
      # @return [RestClient::Response] response object from POST request
      # @return [Nil] if any error occurs
      #
      def run_capture_ready
        puts 'Posting to Tumblr'
        r = client.photo(configuration['tumblr_name'], data: runner.main_image)
        if r.key?('id')
          puts "\t--> Post successful!"
        else
          puts "Tumblr post FAILED! #{r}"
        end
      rescue Faraday::Error => e
        puts "Tumblr post FAILED! #{e.message}"
      end

      def configure_options!
        options = super
        # ask user to configure tokens if enabling
        if options['enabled']
          auth_config = configure_auth!
          return unless auth_config
          options = options.merge(auth_config).merge(configure_tumblr_name)
        end
        options
      end

      def configure_auth!
        puts '---------------------------'
        puts 'Need to grab tumblr tokens'
        puts '---------------------------'

        request_token = oauth_consumer.get_request_token(exclude_callback: true)
        print "\n1) Please open this url in your browser to authorize lolcommits:\n\n"
        puts request_token.authorize_url
        print "\n2) Launching a local server to complete the OAuth authentication process:\n\n"
        begin
          server = WEBrick::HTTPServer.new Port: 3000
          server.mount_proc '/', server_callback(server)
          server.start
          debug "Requesting Tumblr OAuth Token with verifier: #{@verifier}"
          access_token = request_token.get_access_token(oauth_verifier: @verifier)
        rescue Errno::EADDRINUSE
          puts "\nERROR You have something running on port 3000. Please turn it off to complete the authorization process"
          return
        rescue OAuth::Unauthorized
          puts "\nERROR: Tumblr OAuth verification faile!"
          return
        end
        return unless access_token.token && access_token.secret
        puts ''
        puts '------------------------------'
        puts 'Thanks! Tumblr Auth Succeeded'
        puts '------------------------------'

        {
          'access_token' => access_token.token,
          'secret'       => access_token.secret
        }
      end

      def configure_tumblr_name
        print "\n3) What's your tumblr name? (i.e. 'http://[THIS PART HERE].tumblr.com'): "
        { 'tumblr_name' => gets.strip }
      end

      ##
      # Returns true if the plugin has been configured.
      #
      # @return [Boolean] true/false indicating if plugin is configured
      #
      def configured?
        !configuration['enabled'].nil? &&
          configuration['access_token'] &&
          configuration['secret']
      end

      def client
        @client ||= ::Tumblr.new(
          consumer_key: TUMBLR_CONSUMER_KEY,
          consumer_secret: TUMBLR_CONSUMER_SECRET,
          oauth_token: configuration['access_token'],
          oauth_token_secret: configuration['secret']
        )
      end

      def oauth_consumer
        @oauth_consumer ||= OAuth::Consumer.new(
          TUMBLR_CONSUMER_KEY,
          TUMBLR_CONSUMER_SECRET,
          site: TUMBLR_API_ENDPOINT,
          request_endpoint: TUMBLR_API_ENDPOINT,
          http_method: :get
        )
      end

      def config_with_default(key, default = nil)
        if configuration[key]
          configuration[key].strip.empty? ? default : configuration[key]
        else
          default
        end
      end

      protected

      def server_callback(server)
        proc do |req, res|
          q = CGI.parse req.request_uri.query
          @verifier = q['oauth_verifier'][0]
          server.stop
          res.body = 'Lolcommits authorization complete!'
        end
      end
    end
  end
end

#       ##
#       # Initialize plugin with runner, config and set all configurable options.
#       #
#       def initialize(runner: nil, config: nil)
#         super
#         options.concat(plugin_options)
#       end

#       ##
#       # Returns true if the plugin has been configured.
#       #
#       # @return [Boolean] true/false indicating if plugin is configured
#       #
#       def configured?
#         !!(!configuration['enabled'].nil? && configuration['endpoint'])
#       end

#       ##
#       # Returns true/false indicating if the plugin has been correctly
#       # configured. The `endpoint` option must be set with a URL beginning with
#       # http(s)://
#       #
#       # @return [Boolean] true/false indicating if plugin is correctly
#       # configured
#       #
#       def valid_configuration?
#         !!(configuration['endpoint'] =~ /^http(s)?:\/\//)
#       end
#
#       private
#
#       ##
#       # Returns all configuration options available for this plugin.
#       #
#       # @return [Array] the option names
#       #
#       def plugin_options
#         %w(
#           endpoint
#           optional_key
#           optional_http_auth_username
#           optional_http_auth_password
#         )
#       end
