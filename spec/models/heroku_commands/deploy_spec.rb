require "rails_helper"

RSpec.describe HerokuCommands::Deploy, type: :model do
  include SlashHeroku::Support::Helpers::Api

  before do
  end

  def heroku_handler_for(text)
    command = command_for(text)
    command.handler
  end

  it "makes you sign up for GitHub OAuth" do
    command = heroku_handler_for("deploy hubot")
    message = "You're not authenticated with GitHub yet. " \
                "<https://www.example.com/auth/github([^|]+)|Fix that>."

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql("hubot")

    command.run

    expect(command.response[:response_type]).to eql("in_channel")
    expect(command.response[:text]).to match(Regexp.new(message))
    expect(command.response[:attachments]).to be_nil
  end

  # rubocop:disable Metrics/LineLength
  it "has a deploy command" do
    command = heroku_handler_for("deploy hubot to production")
    user = command.user
    user.github_token = Digest::SHA1.hexdigest(Time.now.utc.to_f.to_s)
    user.save
    command.user.reload

    response_info = fixture_data("api.heroku.com/account/info")
    stub_request(:get, "https://api.heroku.com/account")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/pipelines/info")
    stub_request(:get, "https://api.heroku.com/pipelines")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/pipeline-couplings")
    stub_request(:get, "https://api.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/pipeline-couplings")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.heroku.com/apps/27bde4b5-b431-4117-9302-e533b887faaa")
    stub_request(:get, "https://api.heroku.com/apps/27bde4b5-b431-4117-9302-e533b887faaa")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: response_info, headers: {})

    stub_request(:post, "https://api.heroku.com/apps/hubot/builds")
      .with(headers: default_heroku_headers(command.user.heroku_token))
      .to_return(status: 200, body: { id: "191853f6-0635-44cc-8d97-ef8feae0e178" }.to_json, headers: {})

    response_info = fixture_data("kolkrabbi.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/repository")
    stub_request(:get, "https://kolkrabbi.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/repository")
      .to_return(status: 200, body: response_info)

    response_info = fixture_data("api.github.com/repos/atmos/hubot/index")
    stub_request(:get, "https://api.github.com/repos/atmos/hubot")
      .to_return(status: 200, body: response_info, headers: {})

    response_info = fixture_data("api.github.com/repos/atmos/hubot/branches/production")
    stub_request(:get, "https://api.github.com/repos/atmos/hubot/branches/production")
      .to_return(status: 200, body: response_info, headers: {})

    sha = "27bd10a885d27ba4db2c82dd34a199b6a0a8149c"
    response_info = fixture_data("api.github.com/repos/atmos/hubot/tarball/#{sha}")
    stub_request(:head, "https://api.github.com/repos/atmos/hubot/tarball/#{sha}")
      .to_return(status: 200, body: response_info, headers: { "Location" => "https://codeload.github.com/atmos/hubot/legacy.tar.gz/master" })

    url = "https://api.github.com/repos/atmos/hubot/deployments/4307227"
    stub_request(:post, "https://api.github.com/repos/atmos/hubot/deployments")
      .to_return(status: 200, body: { sha: sha, url: url }.to_json, headers: {})

    stub_request(:post, "https://api.github.com/repos/atmos/hubot/deployments/4307227/statuses")
      .to_return(status: 200, body: {}.to_json, headers: {})

    expect(command.task).to eql("deploy")
    expect(command.subtask).to eql("default")
    expect(command.application).to eql("hubot")

    command.run

    message = "<@U123YG08X> is <https://dashboard.heroku.com/apps/hubot" \
                "/activity/builds/191853f6-0635-44cc-8d97-ef8feae0e178|" \
                "deploying> atmos/hubot@master(27bd10a8) to production."

    expect(command.response[:response_type]).to eql("in_channel")
    expect(command.response[:text]).to eql(message)
  end
end
