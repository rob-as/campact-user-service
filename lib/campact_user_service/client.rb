require 'faraday'
require 'json'
require 'base32'
require 'rotp'

module CampactUserService
  class Client
    TIMEOUT = 5

    attr_reader :connection, :scheme, :host, :port

    def initialize(options)
      @scheme = options.fetch(:scheme, 'https')
      @host = options.fetch(:host)
      @port = options[:port]
      faraday_options = default_faraday_options.merge(options.delete(:faraday) || {})
      adapter = faraday_options.delete(:adapter) || Faraday.default_adapter

      @connection = Faraday.new(endpoint, faraday_options) do |faraday|
        if options.has_key?(:enable_auth)
          faraday.basic_auth options[:username], options[:password]
        end
        faraday.adapter adapter
      end
    end

    def get_request(path, options={})
      response = connection.get do |req|
        req.url path
        req.options.timeout = TIMEOUT
        req.options.open_timeout = TIMEOUT
        if options.has_key?(:cookies)
          req.headers['Cookie'] = format_cookies(options[:cookies])
        end
      end

      if response.status == 200
        JSON.parse(response.body)
      else
        nil
      end
    end

    private

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
  end
end
