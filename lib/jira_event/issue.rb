class JiraEvent
  class Issue
    def initialize issue_payload
      @payload = issue_payload
    end

     def title
      @title ||= payload['fields']['summary']
    end

    def key
      @key ||= payload['key']
    end

    def url
      @url ||= %(https://#{JIRA_HOSTNAME}/browse/#{key})
    end

    def description
      @description ||= payload['fields']['description']
    end

    def reporter
      @reporter ||= payload['fields']['reporter']['displayName']
    end

    def hyperlink
      "<a href='#{url}' target='_blank'>#{title} (#{key})</a>"
    end

    private

    attr_reader :payload

  end
end
