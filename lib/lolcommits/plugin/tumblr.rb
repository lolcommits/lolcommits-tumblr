require 'lolcommits/plugin/base'
require 'lolcommits/cli/launcher'
require 'oauth'
require 'webrick'
require 'cgi'
require 'tumblr_client'

module Lolcommits
  module Plugin
    class Tumblr < Base

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
        print "*** Posting to Tumblr ... "
        post = client.photo(configuration['tumblr_name'], data: runner.main_image)

        if post.key?('id')
          post_url = tumblr_post_url(post)
          open_url(post_url) if configuration['open_url']
          print "done! #{post_url}\n"
        else
          print "Post FAILED! #{post.inspect}"
        end
      rescue Faraday::Error => e
        print "Post FAILED! #{e.message}"
      end

      ##
      # Returns true if the plugin has been configured.
      #
      # @return [Boolean] true/false indicating if plugin is configured
      #
      def configured?
        !!(configuration['enabled'] &&
           configuration['access_token'] &&
           configuration['secret'] &&
           configuration['tumblr_name'])
      end

      ##
      # Prompts the user to configure the plugin's options.
      #
      # If the enabled option is set, Ouath configuration is attempted, if
      # successful additional plugin options are asked for to set both
      # `tumblr_name` and `open_url`.
      #
      # @return [Hash] a hash of configured plugin options
      #
      def configure_options!
        options = super
        # ask user to configure tokens if enabling
        if options['enabled']
          auth_config = configure_auth!
          return unless auth_config
          options = options.merge(auth_config).merge(configure_options)
        end
        options
      end


      private

      def configure_auth!
        puts ''
        puts '----------------------------------------'
        puts '    Need to grab Tumblr Oauth token     '
        puts '----------------------------------------'

        request_token = oauth_consumer.get_request_token(exclude_callback: true)
        puts "\nOpening this url to authorize lolcommits:"
        puts request_token.authorize_url
        open_url(request_token.authorize_url)
        puts "\nLaunching local webbrick server to complete the OAuth process ...\n"
        begin
          trap('INT') { local_server.shutdown }
          local_server.mount_proc '/', server_callback
          local_server.start
          debug "Requesting Tumblr OAuth Token with verifier: #{@verifier}"
          access_token = request_token.get_access_token(oauth_verifier: @verifier)
        rescue OAuth::Unauthorized
          puts "ERROR: Tumblr OAuth verification failed!"
          return
        rescue WEBrick::HTTPServerError
          puts "Do you have something running on port 3000? Please turn it off to complete the authorization process"
          return
        end
        return unless access_token.token && access_token.secret

        puts ''
        puts '----------------------------------------'
        puts 'Thanks! Lolcommits Tumblr Auth Succeeded'
        puts '----------------------------------------'

        {
          'access_token' => access_token.token,
          'secret'       => access_token.secret
        }
      end

      def configure_options
        print "\n* What's your Tumblr name? (i.e. 'http://[THIS PART HERE].tumblr.com'): "
        tumblr_name = parse_user_input(gets.strip)
        print "\n* Automatically open Tumblr URL after posting (y/N): "
        open_url = ask_yes_or_no?
        { 'tumblr_name' => tumblr_name, 'open_url' => open_url }
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

      def ask_yes_or_no?(default: false)
        yes_or_no = parse_user_input(gets.strip)
        return default if yes_or_no.nil?
        !!(yes_or_no =~ /^y/i)
      end

      def tumblr_post_url(post)
        "https://#{configuration['tumblr_name']}.tumblr.com/post/#{post['id']}"
      end

      def open_url(url)
        Lolcommits::CLI::Launcher.open_url(url)
      end

      def local_server
        @local_server ||= WEBrick::HTTPServer.new(Port: 3000)
      end

      def oauth_response(heading, message)
        <<-RESPONSE
          <html>
            <head>
              <style>
              body {
                background-color: #36465D;
                text-align: center;
              }

              a { color: #529ecc; text-decoration: none; }
              a img { border: none; }

              img {
                width: 100px;
                margin-top: 100px;
              }

              div {
                margin: 20px auto;
                font: normal 16px "Helvetica Neue", "HelveticaNeue", Helvetica, Arial, sans-serif;
                padding: 20px 40px;
                background: #FEFEFE;
                width: 50%;
                border-radius: 10px;
                color: #757575;
              }

              h1 {
                font-size: 18px;
              }
              </style>
            </head>
            <body>
              <a href="https://lolcommits.github.io">
                <img src="https://lolcommits.github.io/assets/img/logo/lolcommits_logo_400px.png" alt="lolcommits" width="100px" />
              </a>
              <div>
                <h1>#{heading}</h1>
                <p>#{message}</p>
              </div>
            </body>
          </html>
        RESPONSE
      end

      def server_callback
        proc do |req, res|
          local_server.stop
          local_server.shutdown

          query = req.request_uri.query
          query = CGI.parse(req.request_uri.query) if query

          if query && query['oauth_verifier']
            @verifier = query['oauth_verifier'][0]
            res.body = oauth_response(
              "Lolcommits Authorization Complete",
              "Please return to your console to complete the <a href=\"https://github.com/lolcommits/lolcommits-tumblr\">lolcommits-tumblr</a> plugin setup"
            )
          else
            res.body = oauth_response("Lolcommits Authorization Cancelled", ":( Oh well, it was fun to ask")
          end
        end
      end
    end
  end
end
