class JiraEvent
  SUPPORTED_ISSUE_EVENTS   = ['jira:issue_created', 'jira:issue_updated']
  JIRA_HOSTNAME            = ENV['JIRA_HOSTNAME']

  attr_reader :name, :payload, :type, :user

  def initialize payload
    @payload  = payload
    @name     = payload['webhookEvent']
    @type     = payload['issue_event_type_name']
    @user     = payload['user']['displayName']
  end

  def link_to_issue
    "<a href='#{issue_url}' target='_blank'>#{issue_title} (#{issue_key})</a>"
  end

  def content
    @content ||= if issue_related?
      payload['issue']['fields']['description']
    elsif comment_related?
      payload['comment']['body']
    end
  end

  def issue_title
    @issue_title ||= payload['issue']['fields']['summary']
  end

  def issue_key
    @issue_key ||= payload['issue']['key']
  end

  def issue_url
    @issue_url ||= %(https://#{JIRA_HOSTNAME}/browse/#{issue_key})
  end

  def issue_related?
    type.nil?
  end

  def comment_related?
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
    @issue_regex ||= /https:\/\/#{JIRA_HOSTNAME}\/browse\/#{key}/
  end
end
