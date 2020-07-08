module CampactUserService
  class Account
    attr_reader :client, :user_id

    def initialize(client, user_id)
      @client = client
      @user_id = user_id
    end

    def exists?
      account && !account["id"].nil?
    end

    def subscribed_to_newsletter?
      subscriptions = account.dig('emailaddress', 'subscriptions') || []
      subscriptions.any? {|s| s['type'] == 'newsletter' }
    end

    def allow_prefill?
      prefill = account.dig('preferences', 'prefill_forms')
      prefill.to_s == 'allowed'
    end

    def name
      account['name']
    end

    def email
      account.dig('emailaddress', 'emailaddress')
    end

    def address
      account['postaladdress']
    end

    def preferences
      account['preferences']
    end

    private

    def account
      escaped_user_id = CGI.escape(user_id)
      @account_info ||= (client.get_request("api/v1/accounts/#{escaped_user_id}") || {})
    end
  end
end
