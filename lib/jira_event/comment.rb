class JiraEvent
  class Comment
    attr_reader :issue

    def initialize comment_payload, parent_issue
      @payload = comment_payload
      @issue   = parent_issue
    end

    def author
      @author ||= payload['author']['displayName'] if has_payload? && payload['author']
    end

    def body
      @body ||= payload['body'] if has_payload?
    end

    private

    def has_payload?
      payload.present?
    end

    attr_reader :payload

  end
end
