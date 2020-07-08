require 'faraday'
require 'json'
require 'base32'
require 'rotp'
require 'campact_user_service/response_error'

module CampactUserService
  class Client
    TIMEOUT = 5.freeze

    attr_reader :connection, :scheme, :host, :port, :topt_authorization

    def initialize(options)
      @scheme = options.fetch(:scheme, 'https')
      @host = options.fetch(:host)
      @port = options[:port]
      @topt_authorization = options[:topt_authorization]
      faraday_options = default_faraday_options.merge(options.delete(:faraday) || {})
      adapter = faraday_options.delete(:adapter) || Faraday.default_adapter

      @connection = Faraday.new(endpoint, faraday_options) do |faraday|
        faraday.adapter adapter
      end
    end

    %i(get delete).each do |verb|
      define_method("#{verb}_request") do |path, options={}|
        request(verb, path, options)
      end
    end

    private

    def request(verb, path, options)
      response = connection.send(verb.to_sym) do |req|
        req.url path
        req.options.timeout = TIMEOUT
        req.options.open_timeout = TIMEOUT
        if options.key?(:cookies)
          req.headers['Cookie'] = format_cookies(options[:cookies])
        end

        if topt_authorization
          req.headers['authorization'] = authorization(topt_authorization)
        end
      end

      case response.status
      when 200
        body = (response.body.nil? || response.body == '') ? '{ }' : response.body
        JSON.parse(body)
      when 201..299
        true
      when 404
        nil
      when 300..599
        raise ResponseError.new(response.status, response.body)
      else
        nil
      end
    end

    def default_faraday_options
      {
        ssl: { verify: true },
        headers: {
          'Accept' => "application/json;q=0.1",
          'Accept-Charset' => "utf-8",
          'User-Agent' => 'campact_user_service'
        }
      }
    end

    def endpoint
      endpoint = "#{scheme}://#{host}"
      if !port.nil?
        endpoint << ":#{port}"
      end

      endpoint
    end

    def format_cookies(cookies)
      case cookies
        when String
          cookies
        when Hash
          cookies.map {|k,v| "#{k}=#{v};" }.join
      end
    end

    def authorization(totp_options)
      user = totp_options.fetch(:user)
      secret = totp_options.fetch(:secret)

      token = [user, auth_pass(secret)].join(':')

      "Token #{token}"
    end

    def auth_pass(secret)
      totp_secret = ROTP::Base32.encode(secret)

      ROTP::TOTP.new(totp_secret, {
        digest: 'sha256',
        digits: 8,
        interval: 30
      }).now
    end
  end
end
