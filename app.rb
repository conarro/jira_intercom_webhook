require 'bundler'
Bundler.require
require 'logger'
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file; puts "required #{file}" }

INTERCOM_REGEX = /https:\/\/app.intercom.io\/a\/apps\/(?<app_id>\S*)\/inbox\/(\S*\/)?conversation(s)?\/(?<conversation_id>\d*)/
INTERCOM_CLIENT = IntercomApiClient.new(ENV['INTERCOM_APP_ID'], ENV['INTERCOM_API_KEY'])
JIRA_HOSTNAME = ENV['JIRA_HOSTNAME']

configure :production do
  app_logger = Logger.new(STDOUT)
  set :logging, Logger::WARN
  use Rack::CommonLogger, app_logger
  set :dump_errors, false
  set :raise_errors, false
end

configure :development do
  app_logger = Logger.new(STDOUT)
  set :logging, Logger::DEBUG
  use Rack::CommonLogger, app_logger
end

configure :test do
  app_logger = Logger.new('/dev/null')
  set :logging, Logger::WARN
  use Rack::CommonLogger, app_logger
end

use Rack::Auth::Basic, "Restricted Area" do |username, password|
  username == ENV['APP_USERNAME'] and password == ENV['APP_PASSWORD']
end

#################
# helper methods
#
def jira_issue_url key
  %(https://#{JIRA_HOSTNAME}/browse/#{key})
end

def jira_issue_regex key
  /https:\/\/#{JIRA_HOSTNAME}\/browse\/#{key}/
end
#
#################

get '/health' do
  content_type :json
  {status: 'OK'}.to_json
end

post '/jira_to_intercom' do
  content_type :json

  request.body.rewind

  begin
    data = request.body.read
    json = JSON.parse(data)
    if json.empty?
      logger.error('JSON payload is empty')
      halt 500
    end
  rescue JSON::ParserError => ex
    logger.error('Unable to parse JSON.')
    logger.error(ex)
    halt 500
  ensure
    logger.debug(data)
  end

  jira_event = JiraEvent.new(json)

  if jira_event.supported?
    link_finder = IntercomLinkFinder.new(jira_event.content)

    # check if jira event content includes intercom conversation URL
    if link_finder.has_link?

      # get issue info
      issue_title = jira_event.issue_title
      issue_key   = jira_event.issue_key
      issue_url   = jira_event.issue_url

      # get convo
      # TODO: move this into background job
      conversation = INTERCOM_CLIENT.get_conversation(link_finder.conversation_id)

      # check if convo already linked
      if conversation.code == 200

        # issue and convo already linked
        if jira_event.issue_referenced?(conversation.body)

          if jira_event.comment_related?
            logger.debug "Comment event"
            # add jira comment as note in intercom
            @result = INTERCOM_CLIENT.note_conversation(
              link_finder.conversation_id,
              "#{jira_event.user} commented on #{jira_event.link_to_issue}: #{jira_event.content}"
            )
          else
            # nothing to do here
            logger.info("Issue #{issue_key} already linked in Intercom")
            halt 409
          end
        end

      else
        # not linked, let's add a link
        logger.info("Linking issue #{issue_key} in Intercom...")
        @result = INTERCOM_CLIENT.note_conversation(
          link_finder.conversation_id,
          "#{jira_event.user} linked a JIRA ticket: #{jira_event.link_to_issue}"
        )
      end

      @result.to_json
    else
      # no link, nothing to see here
      { :message => 'No Intercom link in the JIRA event' }.to_json
    end
  else
    logger.info("Unsupported JIRA webhook event #{jira_event.name}")
    halt 400
  end
end
