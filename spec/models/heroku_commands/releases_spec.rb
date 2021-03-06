require "rails_helper"

RSpec.describe HerokuCommands::Releases, type: :model do
  include SlashHeroku::Support::Helpers::Api

  before do
    Timecop.freeze(Time.zone.local(2016, 3, 13))
  end

  after do
    Timecop.return
  end

  def heroku_handler_for(text)
    command = command_for(text)
    command.handler
  end

  # rubocop:disable Metrics/LineLength
  it "has a releases -a command" do
    command = heroku_handler_for("releases -a atmos-dot-org")

    response_info = fixture_data("api.heroku.com/releases/atmos-dot-org/list")
    stub_request(:get, "https://api.heroku.com/apps/atmos-dot-org/releases")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    expect(command.task).to eql("releases")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql("atmos-dot-org")
    expect { command.run }.to_not raise_error

    expect(command.response[:response_type]).to eql("in_channel")
    expect(command.response[:attachments].size).to eql(1)
    attachment = command.response[:attachments].first
    expect(attachment[:fallback])
      .to eql("Latest releases for Heroku application atmos-dot-org")
    expect(attachment[:pretext]).to eql(nil)
    expect(attachment[:text].split("\n").size).to eql(9)
    expect(attachment[:title])
      .to eql("<https://dashboard.heroku.com/apps/atmos-dot-org|atmos-dot-org> - Recent releases")
    expect(attachment[:title_link]).to eql(nil)
    expect(attachment[:fields]).to eql(nil)
  end
  # rubocop:enable Metrics/LineLength

  describe "release:info" do
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/LineLength
    def verify_release(response)
      expect(response[:text]).to eql(nil)
      expect(response[:attachments].size).to eql(1)

      attachment = response[:attachments].first
      expect(attachment[:fallback])
        .to eql("Heroku release for atmos-dot-org:v9")
      expect(attachment[:text]).to eql(nil)
      expect(attachment[:title])
        .to eql("<https://dashboard.heroku.com/apps/atmos-dot-org|atmos-dot-org> - v9 - Deploy 774377e")
      expect(attachment[:title_link]).to eql(nil)
      expect(attachment[:fields].size).to eql(2)

      fields = attachment[:fields]
      expect(fields.first[:title]).to eql("By")
      expect(fields.first[:value]).to eql("atmos@atmos.org")
      expect(fields.last[:title]).to eql("When")
      expect(fields.last[:value]).to eql("3 months")
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/LineLength

    it "supports numbered releases" do
      command = heroku_handler_for("releases:info 9 -a atmos-dot-org")

      response_info = fixture_data("api.heroku.com/releases/atmos-dot-org/info")
      stub_request(:get, "https://api.heroku.com/apps/atmos-dot-org/releases/9")
        .with(headers: default_heroku_headers(command.user.heroku_token))
        .to_return(status: 200, body: response_info, headers: {})

      expect(command.task).to eql("releases")
      expect(command.subtask).to eql("info")
      expect(command.application).to eql("atmos-dot-org")
      expect { command.run }.to_not raise_error

      verify_release(command.response)
    end

    it "supports numbered releases with v prefix" do
      command = heroku_handler_for("releases:info v9 -a atmos-dot-org")

      response_info = fixture_data("api.heroku.com/releases/atmos-dot-org/info")
      stub_request(:get, "https://api.heroku.com/apps/atmos-dot-org/releases/9")
        .with(headers: default_heroku_headers(command.user.heroku_token))
        .to_return(status: 200, body: response_info, headers: {})

      expect(command.task).to eql("releases")
      expect(command.subtask).to eql("info")
      expect(command.application).to eql("atmos-dot-org")
      expect { command.run }.to_not raise_error

      verify_release(command.response)
    end
  end

  it "has a release:rollback -a command" do
    id = "49d3122d-f273-4e34-afec-337a8b107e48"
    heroku_handler_for("releases:rollback #{id} -a atmos-dot-org")

    pending "releases:rollback is unimplemented"

    raise ArgumentError, "releases:rollback is unimplemented"
  end
end
