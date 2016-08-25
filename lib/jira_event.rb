require_relative './jira_event/issue'
require_relative './jira_event/comment'

class JiraEvent
  SUPPORTED_ISSUE_EVENTS   = ['jira:issue_created', 'jira:issue_updated']
  JIRA_HOSTNAME            = ENV['JIRA_HOSTNAME']

  attr_reader :name, :payload, :type, :issue, :comment

  def initialize payload
    @payload  = payload
    @name     = payload['webhookEvent']
    @type     = payload['issue_event_type_name']

    @issue    = Issue.new(payload['issue'])
    @comment  = Comment.new(payload['comment'], issue)
  end

  def content
    @content ||= [issue.description, comment.body].join
  end

  def issue_created?
    name == 'jira:issue_created'
  end

  def issue_updated?
    name == 'jira:issue_updated'
  end

  def issue_commented?
    type && type == 'issue_commented'
  end

  def supported?
    SUPPORTED_ISSUE_EVENTS.include?(name)
  end

  def issue_referenced? content
    issue_regex.match(content)
  end

  private

  def issue_regex
    @issue_regex ||= /https:\/\/#{JIRA_HOSTNAME}\/browse\/#{issue.key}/
  end
end
