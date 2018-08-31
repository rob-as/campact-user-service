module CampactUserService
  class Session
    attr_reader :client, :session_cookie_name, :session_id

    def initialize(client, session_id, session_cookie_name)
      @client = client
      @session_id = session_id
      @session_cookie_name = session_cookie_name
    end

    def exists?
      session && session['id']
    end

    def user_id
      session["user_id"]
    end

    def has_soft_login_session?
      session["permission_level"] == 'limited'
    end

    def has_hard_login_session?
      session["permission_level"] == 'full'
    end

    private

    def session
      @session_info ||= (client.get_request('/v1/sessions', cookies: {session_cookie_name => session_id}) || {})
    end
  end
end
