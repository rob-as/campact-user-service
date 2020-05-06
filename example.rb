$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

require 'campact_user_service'
require 'faraday/detailed_logger'

def instrument_connection_with_extended_logging(client, username, password)
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
    faraday.basic_auth username, password
    faraday.adapter Faraday.default_adapter
  end

  instrumented_connection = Faraday.new(
    "#{client.scheme}://#{client.host}:#{client.port}",
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

# Get username
puts "I'll need your API credentials"
puts "Enter your API username"
username = gets.chomp

# Get password
puts "I'll need your password now"
password = gets.chomp

# Now connect to the right API
user_service = case option
when '1'
  puts "Now I'll need a session token"
  token = gets.chomp
  session = CampactUserService.session(
    token,
    'campact-demo-session',
    {
      scheme: 'http',
      host: 'demo.campact.de',
      port: '10004'
    }
  )
when '2'
  puts "I'll need a user ID (email address). In practice I won't need this here because it can be derived through the session token"
  user_id = gets.chomp
  account = CampactUserService.account(
    user_id,
    {
      scheme: 'http',
      host: 'demo.campact.de',
      port: '10003'
    }
  )
else
  raise 'Invalid option'
end

instrument_connection_with_extended_logging(user_service.client, username, password)

puts "Waiting for your command..."
require 'pry-byebug'
binding.pry # rubocop:disable Lint/Debugger

puts 'Goodbye!'
