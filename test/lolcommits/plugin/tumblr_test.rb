# frozen_string_literal: true

require "json"
require 'net/http'
require "test_helper"
require "webmock/minitest"

describe Lolcommits::Plugin::Tumblr do

  include Lolcommits::TestHelpers::GitRepo
  include Lolcommits::TestHelpers::FakeIO

  describe "with a runner" do
    def runner
      # a simple lolcommits runner with an empty configuration Hash
      @runner ||= Lolcommits::Runner.new(
        lolcommit_path: Tempfile.new("lolcommit.jpg").path
      )
    end

    def plugin
      @plugin ||= Lolcommits::Plugin::Tumblr.new(runner: runner)
    end

    def valid_enabled_config
      {
        enabled: true,
        access_token: "tumblr-access-token",
        secret: "tumblr-secret",
        tumblr_name: "my-tumblr",
        open_url: false
      }
    end

    describe "#enabled?" do
      it "is false by default" do
        _(plugin.enabled?).must_equal false
      end

      it "is true when configured" do
        plugin.configuration = valid_enabled_config
        _(plugin.enabled?).must_equal true
      end
    end

    describe "run_capture_ready" do
      before { commit_repo_with_message("first commit!") }
      after { teardown_repo }

      it "posts lolcommit to tumblr showing link to new photo post" do
        in_repo do
          plugin.configuration = valid_enabled_config

          stub_request(:post, "https://api.tumblr.com/v2/blog/my-tumblr/post").to_return(
            body: {
              "meta" => { "status" => 201, "msg" => "Created"},
              "response" => { "id" => 123456789 }
            }.to_json,
            headers: { "Content-Type" => "application/json" },
            status: 201
          )

          output = fake_io_capture { plugin.run_capture_ready }
          _(output).must_match "done! https://my-tumblr.tumblr.com/post/123456789"

          assert_requested :post, "https://api.tumblr.com/v2/blog/my-tumblr/post", times: 1,
            headers: { "Content-Type" => /multipart\/form-data/, "Accept" => "application/json" } do |req|
            _(req.body).must_match 'filename="lolcommit.jpg'
          end
        end
      end
    end

    describe "valid_configuration?" do
      it "returns invalid config when partially configured" do
        plugin.configuration = { tumblr_name: "fire" }
        _(plugin.valid_configuration?).must_equal false
      end

      it "returns true with a valid configuration" do
        plugin.configuration = valid_enabled_config
        _(plugin.valid_configuration?).must_equal true
      end
    end

    describe "configuration" do
      it "allows plugin options to be configured" do
        # allow requests to localhost for this test
        WebMock.disable_net_connect!(allow_localhost: true)

        # enabled tumblr_name caption_erb open_url
        inputs = [true, 'my-tumblr', ' ', 'Y']
        configured_plugin_options = {}

        # stub Oauth token request flow
        stub_request(:get, "https://www.tumblr.com/oauth/request_token").to_return(
          status: 200,
          body: "oauth_token=mytoken&oauth_token_secret=mytokensercet&oauth_callback_confirmed=true"
        )

        stub_request(:get, "https://www.tumblr.com/oauth/access_token").to_return(
          status: 200,
          body: "oauth_token=tumblr-access-token&oauth_token_secret=tumblr-secret"
        )

        # fake clicking authorize app in Tumblr by hitting local webrick server
        # this will loop and request until the server responds 200 OK
        fork do
          res = nil
          while !res || res.code != "200"
            uri = URI('http://localhost:3000/?oauth_verifier[]=my-verifier')
            res = Net::HTTP.get_response(uri) rescue nil
            sleep 0.1
          end
        end

        fake_io_capture(inputs: inputs) do
          configured_plugin_options = plugin.configure_options!
        end

        _(configured_plugin_options).must_equal({
          enabled: true,
          access_token: "tumblr-access-token",
          secret: "tumblr-secret",
          tumblr_name: "my-tumblr",
          open_url: true,
          caption_erb: nil
        })

        WebMock.disable_net_connect!
      end
    end
  end
end
