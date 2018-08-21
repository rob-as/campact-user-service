module CampactUserService
  class Account
    attr_reader :client, :session_cookie_name, :session_id, :user_id

    def initialize(client, session_id, session_cookie_name, user_id)
      @client = client
      @session_id = session_id
      @session_cookie_name = session_cookie_name
      @user_id = user_id
    end

    def exists?
      account && account['id']
    end

    def allow_prefill?
      prefill = account.dig("preferences", "prefill_forms")
      prefill.to_s == 'allowed'
    end

    def name
      account["name"]
    end

    def email
      account.dig("emailaddress", "emailaddress")
    end

    def address
      account["postaladdress"]
    end

    def preferences
      account["preferences"]
    end

    def donor_info
      account["donorclass"]
    end

    private

    def account
      @account_info ||= client.get_request(
        "accounts/v1/#{user_id}",
        cookies: {session_cookie_name => session_id}
      )
    end
  end
end
