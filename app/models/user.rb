# A user from the Slack API
class User < ApplicationRecord
  include TokenManagement
  include GitHubTokenManagement
  include HerokuTokenManagement

  has_many :commands, dependent: :destroy

  def self.omniauth_user_data(omniauth_info)
    token = omniauth_info[:credentials][:token]
    response = slack_client.get("/api/users.identity?token=#{token}")

    JSON.parse(response.body)
  end

  def self.from_omniauth(omniauth_info)
    body = omniauth_user_data(omniauth_info)

    user = find_or_initialize_by(
      slack_user_id: body["user"]["id"]
    )
    user.slack_team_id   = body["team"]["id"]
    user.slack_user_name = body["user"]["name"]
    user.save
    user
  end

  def self.slack_client
    Faraday.new(url: "https://slack.com") do |connection|
      connection.headers["Content-Type"] = "application/json"
      connection.adapter Faraday.default_adapter
    end
  end

  def heroku_api
    @heroku_api ||= HerokuApi.new(heroku_token)
  end

  def heroku_user_information
    return nil unless heroku_configured?
    heroku_api.user_information
  end

  def create_command_for(params)
    command = commands.create(
      channel_id: params[:channel_id],
      channel_name: params[:channel_name],
      command: params[:command],
      command_text: params[:text],
      response_url: params[:response_url],
      team_id: params[:team_id],
      team_domain: params[:team_domain]
    )
    CommandExecutorJob.perform_later(command_id: command.id)
    YubikeyExpireJob.set(wait: 10.seconds).perform_later(command_id: command.id)
    command
  end
end
