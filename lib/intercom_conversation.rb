class IntercomConversation
  attr_reader :api_response

  def initialize api_response
    @api_response = api_response
  end

  def body
    @body ||= api_response['conversation_parts']['conversation_parts'].map {|p| p['body'] }.compact.join
  end

  def code
    @code ||= api_response.code
  end
end
