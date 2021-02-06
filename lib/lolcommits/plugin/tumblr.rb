# frozen_string_literal: true

require "lolcommits/plugin/base"
require "lolcommits/cli/launcher"
require "oauth"
require "webrick"
require "cgi"
require "erb"
require "faraday"
require "faraday_middleware"

module Lolcommits
  module Plugin
    class Tumblr < Base

      TUMBLR_API_HOST        = "api.tumblr.com".freeze
      TUMBLR_API_ENDPOINT    = "https://www.tumblr.com".freeze
      TUMBLR_CONSUMER_KEY    = "2FtMEDpEPkxjoUdkpHh42h9wqTu9IVS7Ra0QyNZGixdCvhllN2".freeze
      TUMBLR_CONSUMER_SECRET = "qWuvxgFUR2YyWKtbWOkDTMAiBEbj7ZGaNLaNQPba0PI1N4JpBs".freeze

      ##
      # Post-capture hook, runs after lolcommits captures a snapshot.
      #
      # Posts the lolcommit main image to Tumblr, printing success or
      # failure message to stdout.
      #
      def run_capture_ready
        if runner.capture_video && !runner.capture_gif
          debug "unable to post videos, (Tumblr API only supports images)"
          return
        end

        print "*** Posting to Tumblr ... "
        response = tumblr_api.post do |req|
          req.url "v2/blog/#{configuration[:tumblr_name]}/post"
          req.body = {
            caption: tumblr_caption,
            type: "photo",
            data: Faraday::FilePart.new(lolcommit_path, lolcommit_mime_type)
          }
        end

        post = response.body["response"] || {}

        if post.key?('id')
          post_url = tumblr_post_url(post)
          open_url(post_url) if configuration[:open_url]
          print "done! #{post_url}\n"
        else
          print "Post FAILED! #{response.inspect}"
        end
      rescue Faraday::Error => e
        print "Post FAILED! #{e.message}"
      end

      ##
      # Returns true if the plugin has been configured correctly
      #
      # @return [Boolean] true/false indicating if plugin has a valid config
      #
      def valid_configuration?
        !!(configuration[:access_token] &&
           configuration[:secret] &&
           configuration[:tumblr_name])
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
        if options[:enabled]
          auth_config = configure_auth!
          return unless auth_config
          options = options.merge(auth_config).merge(configure_tumblr)
        end
        options
      end


      private

      def lolcommit_path
        runner.capture_image? ? runner.lolcommit_path : runner.lolcommit_gif_path
      end

      def lolcommit_mime_type
        runner.capture_image? ?  "image/jpeg" : "image/gif"
      end

      def tumblr_api
        # TODO: maybe remove faraday, just use Net::HTTP and simpler code for
        # Oauth1.0 auth (so we can remove a few runtime deps)
        @tumblr_api ||= Faraday.new(url: "https://#{TUMBLR_API_HOST}/", headers: api_headers) do |conn|
          conn.request :oauth, api_oauth
          conn.request :multipart
          conn.request :url_encoded
          conn.response :json, :content_type => /\bjson$/
          conn.adapter Faraday.default_adapter
        end
      end

      def api_headers
        {
          accept: "application/json",
          user_agent: "lolcommits-tumblr/#{Lolcommits::Tumblr::VERSION}"
        }
      end

      def api_oauth
        {
          consumer_key: TUMBLR_CONSUMER_KEY,
          consumer_secret: TUMBLR_CONSUMER_SECRET,
          token: configuration[:access_token],
          token_secret: configuration[:secret]
        }
      end

      def configure_auth!
        puts ""
        puts "----------------------------------------"
        puts "    Need to grab Tumblr Oauth token     "
        puts "----------------------------------------"

        request_token = oauth_consumer.get_request_token(exclude_callback: true)
        puts "\nOpening this url to authorize lolcommits:"
        puts request_token.authorize_url
        open_url(request_token.authorize_url)
        puts "\nLaunching local webbrick server to complete the OAuth process ...\n"
        begin
          trap("INT") { local_server.shutdown }
          trap("SIGTERM") { local_server.shutdown }
          local_server.mount_proc "/", server_callback
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

        puts ""
        puts "----------------------------------------"
        puts "Thanks! Lolcommits Tumblr Auth Succeeded"
        puts "----------------------------------------"

        {
          access_token: access_token.token,
          secret: access_token.secret
        }
      end

      def configure_tumblr
        print "\n* What's your Tumblr name? (i.e. 'http://[THIS PART HERE].tumblr.com'): "
        tumblr_name = parse_user_input(gets.strip)
        print "\n* Optional caption (ERB friendly with vars message, sha, repo, branch, vcs_info)"
        print "\n  e.g. Committed <%= sha %> in <%= repo %> on <%= branch %> - <%= message %>\n\n"
        caption_erb = parse_user_input(gets.strip)
        print "\n* Automatically open Tumblr URL after posting (y/N): "
        open_url = ask_yes_or_no?
        { tumblr_name: tumblr_name, open_url: open_url, caption_erb: caption_erb }
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

      def ask_yes_or_no?(default: false)
        yes_or_no = parse_user_input(gets.strip)
        return default if yes_or_no.nil?
        !!(yes_or_no =~ /^y/i)
      end

      def tumblr_post_url(post)
        "https://#{configuration[:tumblr_name]}.tumblr.com/post/#{post["id"]}"
      end

      def tumblr_caption
        return if configuration[:caption_erb].to_s.strip.empty?

        ERB.new(configuration[:caption_erb]).result(
          binding.tap do |bind|
            vcs_info = runner.vcs_info
            bind.local_variable_set(:message, vcs_info.message)
            bind.local_variable_set(:sha, vcs_info.sha)
            bind.local_variable_set(:repo, vcs_info.repo)
            bind.local_variable_set(:branch, vcs_info.branch)
            bind.local_variable_set(:vcs_info, vcs_info)
          end
        )
      end

      def open_url(url)
        Lolcommits::CLI::Launcher.open_url(url)
      end

      def local_server
        @local_server ||= WEBrick::HTTPServer.new(
          Port: 3000,
          Logger: null_logger,
          AccessLog: null_logger
        )
      end

      def null_logger
        WEBrick::Log.new(nil, -1)
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

          if query && query["oauth_verifier"]
            @verifier = query["oauth_verifier"][0]
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
