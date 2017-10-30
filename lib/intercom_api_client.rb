require 'httparty'

class IntercomApiClient
  include HTTParty
  base_uri 'https://api.intercom.io'

  attr_reader :default_params

  def initialize(token)
    auth = "Bearer " + token
    @default_params = {
      :headers => {
        'Accept'       => 'application/json',
        'Content-Type' => 'application/json',
        "Authorization" => auth
      }
    }
  end

  def get_conversation id, params={}
    params.merge!(default_params)
    response = self.class.get("/conversations/#{id}", params)
    IntercomConversation.new(response)
  end

  # add a private note to the conversation
  #
  def note_conversation id, note
    params = default_params.merge({
      body: {
        body: note,
        type: 'admin',
        # id of admin user to attribute note to
        admin_id: ENV['INTERCOM_ADMIN_ID'],
        message_type: 'note'
      }.to_json
    })
    self.class.post("/conversations/#{id}/reply", params)
  end

end
