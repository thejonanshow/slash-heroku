ENV["APP_NAME"] = "slash-heroku"
ENV["HOSTNAME"] = "www.example.com"
ENV["SLACK_APP_URL"] = "https://slack.com/apps/manage/A0SFS6WSD-heroku"
ENV["KOLKRABBI_HOSTNAME"] = "kolkrabbi.com"
ENV["PRIVACY_POLICY_URL"] = "https://www.example.com/privacy.html"
ENV["SLACK_SLASH_COMMAND_TOKEN"] = "secret-slack-token"
ENV["FERNET_SECRET"] = "2bb0Wq1HJDPg2eLRnvTbKh8xPtJzqJnonOi3fDyVIJ8="
ENV["GITHUB_ADMIN_LOGINS"] = "atmos"

require "webmock/rspec"

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include(WebMock::API)

  config.before(:each) do
    WebMock.reset!
    WebMock.disable_net_connect!
  end

  def github_omniauth_hash_for_atmos
    user_info = {
      name: "Corey Donohoe",
      nickname: "atmos",
      avatar_url: "https://avatars.githubusercontent.com/u/38?v=3"
    }

    credentials = {
      token: SecureRandom.hex(24)
    }

    OmniAuth::AuthHash.new(provider: "github",
                           uid: "38",
                           info: user_info,
                           credentials: credentials)
  end

  # rubocop:disable Metrics/LineLength
  def heroku_omniauth_hash_for_atmos
    info = {
      name:  "Corey Donohoe",
      email: "atmos@atmos.org",
      image: "https://secure.gravatar.com/avatar/09d370bd2f0d8da27c21ba112fd7e0b9.png?d=https://dashboard.heroku.com/ninja-avatar-48x48.png"
    }

    extra_info = {
      email: "atmos@atmos.org",
      name: "Corey Donohoe",
      verified: true
    }

    credentials = {
      token: SecureRandom.hex(24),
      refresh_token: SecureRandom.hex(24),
      expires_at: (Time.now.to_i + 3000)
    }

    OmniAuth::AuthHash.new(provider: "heroku",
                           uid: "49221696-76e4-43ab-8f21-a3e9dcbca72e",
                           info: info,
                           extra: extra_info,
                           credentials: credentials)
  end

  def slack_omniauth_hash_for_atmos
    info = {
      description: nil,
      email: "atmos@atmos.org",
      first_name: "Corey",
      last_name: "Donohoe",
      image: "https://secure.gravatar.com/avatar/a86224d72ce21cd9f5bee6784d4b06c7.jpg?s=192&d=https%3A%2F%2Fslack.global.ssl.fastly.net%2F7fa9%2Fimg%2Favatars%2Fava_0010-192.png",
      image_48: "https://secure.gravatar.com/avatar/a86224d72ce21cd9f5bee6784d4b06c7.jpg?s=48&d=https%3A%2F%2Fslack.global.ssl.fastly.net%2F66f9%2Fimg%2Favatars%2Fava_0010-48.png",
      is_admin: true,
      is_owner: true,
      name: "Corey Donohoe",
      nickname: "atmos",
      team: "Zero Fucks LTD",
      team_id: "T123YG08V",
      time_zone: "America/Los_Angeles",
      user: "atmos",
      user_id: "U123YG08X"
    }
    credentials = {
      token: SecureRandom.hex(24)
    }

    OmniAuth::AuthHash.new(provider: "slack",
                           uid: "U024YG08X",
                           info: info,
                           credentials: credentials)
  end

  # rubocop:disable Metrics/MethodLength
  def slack_omniauth_hash_for_non_admin
    info = {
      provider: "slack",
      uid: nil,
      info: {
      },
      credentials: {
        token: "xoxp-9101111159-5657146422-59735495733-3186a13efg",
        expires: false
      },
      extra: {
        raw_info: {
          ok: false,
          error: "missing_scope",
          needed: "identify",
          provided: "identity.basic"
        },
        web_hook_info: {
        },
        bot_info: {
        },
        user_info: {
          ok: false,
          error: "missing_scope",
          needed: "users:read",
          provided: "identity.basic"
        },
        team_info: {
          ok: false,
          error: "missing_scope",
          needed: "team:read",
          provided: "identity.basic"
        }
      }
    }
    OmniAuth::AuthHash.new(info)
  end
  # rubocop:enable Metrics/MethodLength

  def create_atmos
    slack = slack_omniauth_hash_for_atmos
    options = {
      slack_user_id: slack.info.user_id,
      slack_user_name: slack.info.name,
      slack_team_id: slack.info.team_id
    }
    User.create(options)
  end

  def command_params_for(text)
    {
      channel_id: "C99NNAY74",
      channel_name: "zf-promo",
      command: "/heroku",
      response_url: "https://hooks.slack.com/commands/T123YG08V/2459573/mfZPdDq",
      team_id: "T123YG08V",
      team_domain: "zf",
      text: text
    }
  end

  def command_for(text)
    user = create_atmos
    user.heroku_token         = SecureRandom.hex(24)
    user.heroku_refresh_token = SecureRandom.hex(24)
    user.heroku_expires_at    = 6.hours.from_now
    user.save
    user.create_command_for(command_params_for(text))
  end

  def fixture_data(name)
    path = File.join(fixture_path, "#{name}.json")
    File.read(path)
  end

  def decoded_fixture_data(name)
    JSON.parse(fixture_data(name))
  end
end
