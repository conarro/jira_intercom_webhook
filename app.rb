require 'bundler'
Bundler.require
require 'logger'
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

INTERCOM_REGEX = /https:\/\/app.intercom.io\/a\/apps\/(?<app_id>\S*)\/inbox\/(\S*\/)?conversation(s)?\/(?<conversation_id>\d*)/
INTERCOM_CLIENT = IntercomApiClient.new(ENV['INTERCOM_APP_ID'], ENV['INTERCOM_API_KEY'])
JIRA_HOSTNAME = ENV['JIRA_HOSTNAME']

configure :production do
  app_logger = Logger.new(STDOUT)
  set :logging, true
  use Rack::CommonLogger, app_logger
  set :dump_errors, true
  set :raise_errors, false
end

configure :development do
  app_logger = Logger.new(STDOUT)
  set :logging, true
  use Rack::CommonLogger, app_logger
end

use Rack::Auth::Basic, "Restricted Area" do |username, password|
  username == ENV['APP_USERNAME'] and password == ENV['APP_PASSWORD']
end

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
      issue = jira_event.issue

      # get convo
      # TODO: move this into background job
      conversation = INTERCOM_CLIENT.get_conversation(link_finder.conversation_id)

      # check if convo already linked
      if conversation.code == 200

        # issue and convo already linked
        if jira_event.issue_referenced?(conversation.body)

          if jira_event.issue_commented?
            comment = jira_event.comment

            logger.debug("Comment event")
            logger.info("Adding note for comment on issue #{issue.key} in Intercom...")
            # add jira comment as note in intercom
            @result = INTERCOM_CLIENT.note_conversation(
              link_finder.conversation_id,
              "#{comment.author} commented on #{issue.hyperlink}: #{comment.body}"
            )
          else
            # nothing to do here
            logger.info("Issue #{issue.key} already linked in Intercom")
            halt 409
          end
        end

      else
        # not linked, let's add a link
        logger.info("Linking issue #{issue.key} in Intercom...")
        @result = INTERCOM_CLIENT.note_conversation(
          link_finder.conversation_id,
          "#{issue.reporter} linked a JIRA ticket: #{issue.hyperlink}"
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
