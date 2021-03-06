require "rails_helper"

RSpec.describe HerokuCommands::Pipelines, type: :model do
  include SlashHeroku::Support::Helpers::Api

  before do
  end

  def not_found_response
    {
      message: "Not Found",
      documentation_url: "https://developer.github.com/v3"
    }.to_json
  end

  def heroku_handler_for(text)
    command = command_for(text)
    command.handler
  end

  # rubocop:disable Metrics/LineLength
  it "has a pipeline:info command" do
    command = heroku_handler_for("pipelines:info -a hubot")
    command.user.github_token = SecureRandom.hex(24)
    command.user.save

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

    response_info = fixture_data("kolkrabbi.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/repository")
    stub_request(:get, "https://kolkrabbi.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/repository")
      .to_return(status: 200, body: response_info)

    response = fixture_data("api.github.com/repos/atmos/hubot/index")
    stub_request(:get, "https://api.github.com/repos/atmos/hubot")
      .with(headers: default_github_headers(command.user.github_token))
      .to_return(status: 200, body: response, headers: {})

    response_info = fixture_data("api.github.com/repos/atmos/hubot/branches/production")
    stub_request(:get, "https://api.github.com/repos/atmos/hubot/branches/production")
      .to_return(status: 200, body: response_info, headers: {})

    expect(command.task).to eql("pipelines")
    expect(command.subtask).to eql("info")
    expect(command.application).to eql("hubot")

    command.run

    expect(command.response[:response_type]).to eql("in_channel")
    expect(command.response[:attachments].size).to eql(1)
    attachment = command.response[:attachments].first
    expect(attachment[:fallback])
      .to eql("Heroku app hubot (atmos/hubot)")
    expect(attachment[:pretext]).to eql(nil)
    expect(attachment[:text]).to be_nil
    expect(attachment[:title]).to eql("Application: hubot")
    expect(attachment[:title_link]).to eql(nil)

    heroku_cell = attachment[:fields][0]
    expect(heroku_cell).to_not be_nil
    expect(heroku_cell[:title]).to eql("Heroku")
    expect(heroku_cell[:value]).to eql("<https://dashboard.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111|hubot>")

    github_cell = attachment[:fields][1]
    expect(github_cell).to_not be_nil
    expect(github_cell[:title]).to eql("GitHub")
    expect(github_cell[:value]).to eql("<https://github.com/atmos/hubot|atmos/hubot>")

    production_cell = attachment[:fields][2]
    expect(production_cell).to_not be_nil
    expect(production_cell[:title]).to eql("Production Apps")
    expect(production_cell[:value]).to eql("hubot")

    staging_cell = attachment[:fields][3]
    expect(staging_cell).to_not be_nil
    expect(staging_cell[:title]).to eql("Staging Apps")
    expect(staging_cell[:value]).to eql("<https://dashboard.heroku.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111|Create One>")

    required_contexts_cell = attachment[:fields][4]
    expect(required_contexts_cell).to_not be_nil
    expect(required_contexts_cell[:title]).to eql("Required Contexts")
    expect(required_contexts_cell[:value])
      .to eql("<https://github.com/atmos/hubot/settings/branches/production|Add Required Contexts>")

    environment_cell = attachment[:fields][5]
    expect(environment_cell).to_not be_nil
    expect(environment_cell[:title]).to eql("Default Environment")
    expect(environment_cell[:value]).to eql("production")

    branch_cell = attachment[:fields][6]
    expect(branch_cell).to_not be_nil
    expect(branch_cell[:title]).to eql("Default Branch")
    expect(branch_cell[:value]).to eql("production")
  end

  it "tells you to login to GitHub if pipeline:info can't auth" do
    command = heroku_handler_for("pipelines:info -a hubot")
    command.user.github_token = SecureRandom.hex(24)
    command.user.save

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

    response_info = fixture_data("kolkrabbi.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/repository")
    stub_request(:get, "https://kolkrabbi.com/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/repository")
      .to_return(status: 200, body: response_info)

    stub_request(:get, "https://api.github.com/repos/atmos/hubot")
      .with(headers: default_github_headers(command.user.github_token))
      .to_return(status: 404, body: not_found_response, headers: {})

    stub_request(:get, "https://api.github.com/repos/atmos/hubot/branches/master")
      .to_return(status: 404, body: not_found_response, headers: {})

    expect(command.task).to eql("pipelines")
    expect(command.subtask).to eql("info")
    expect(command.application).to eql("hubot")

    command.run

    response = command.response
    expect(response[:response_type]).to eql("in_channel")
    expect(response[:text]).to include("You're not authenticated with GitHub.")
  end
  # rubocop:enable Metrics/LineLength
end
