class JiraEvent
  class Comment
    attr_reader :issue

    def initialize comment_payload, parent_issue
      @payload = comment_payload || {}
      @issue   = parent_issue
    end

    def author
      @author ||= payload['author']['displayName'] if payload['author']
    end

    def body
      @body ||= payload['body']
    end

    private

    attr_reader :payload

  end
end
