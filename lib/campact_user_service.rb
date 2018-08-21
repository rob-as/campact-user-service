require 'campact_user_service/client'
require 'campact_user_service/session'
require 'campact_user_service/account'
require 'active_support'

module CampactUserService
  class << self
    def session(session_id, session_cookie_name, options)
      client = CampactUserServiceApi::Client.new(options)
      CampactUserServiceApi::Session.new(client, session_id, session_cookie_name)
    end

    def account(session_id, session_cookie_name, options)
      client = CampactUserServiceApi::Client.new(options)
      CampactUserServiceApi::Account.new(client, session_id, session_cookie_name)
    end
  end
end
