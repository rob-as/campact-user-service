module CampactUserService
  class Session
    attr_reader :client, :session_cookie_name, :session_id

    def initialize(client, session_id, session_cookie_name)
      @client = client
      @session_id = session_id
      @session_cookie_name = session_cookie_name
    end

    def user_id
      session and session["user_id"]
    end

    private

    def session
      @session_info ||= client.get_request(
        '/v1/sessions', 
        cookies: {session_cookie_name => session_id}
      )
    end
  end
end
