$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

require 'campact_user_service'
require 'faraday/detailed_logger'

def instrument_connection_with_extended_logging(client)
  default_options = {
    ssl: { verify: true },
    headers: {
      'Accept' => "application/json;q=0.1",
      'Accept-Charset' => "utf-8",
      'User-Agent' => 'campact_user_service'
    }
  }

  faraday_builder = ->(faraday) do
    faraday.response :detailed_logger
    faraday.adapter Faraday.default_adapter
  end

  instrumented_connection = Faraday.new(
    "#{client.scheme}://#{client.host}",
    default_options,
    &faraday_builder
  )
  client.instance_variable_set(:@connection, instrumented_connection)
end

# Pick which API to connect to
# 1 for session
# 2 for user
puts "Which user service are you going to use?\n\t1) session\n\t2) user"
option = gets.chomp

# Get TOTP credentials
username = if ENV['TOTP_USER'].nil?
  puts "I'll need your API credentials"
  puts "Enter your TOTP user"
  gets.chomp
else
  ENV['TOTP_USER']
end

secret = if ENV['TOTP_SECRET'].nil?
  puts "Enter your TOTP secret"
  gets.chomp
else
  ENV['TOTP_SECRET']
end

# Now connect to the right API
user_service = case option
when '1'
  puts "Now I'll need a session token"
  token = gets.chomp
  session = CampactUserService.session(
    token,
    'campact-staging-session',
    {
      scheme: 'https',
      host: 'weact-adapter.staging.campact.de',
      topt_authorization: {user: username, secret: secret}
    }
  )
when '2'
  puts "I'll need a user ID (email address). In practice I won't need this here because it can be derived through the session token"
  user_id = gets.chomp
  account = CampactUserService.account(
    user_id,
    {
      scheme: 'https',
      host: 'weact-adapter.staging.campact.de',
      topt_authorization: {user: username, secret: secret}
    }
  )
else
  raise 'Invalid option'
end

instrument_connection_with_extended_logging(user_service.client)

puts "Waiting for your command..."
require 'pry-byebug'
binding.pry # rubocop:disable Lint/Debugger

puts 'Goodbye!'
