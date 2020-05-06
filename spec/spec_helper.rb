$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'webmock/rspec'
require 'campact_user_service'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each {|f| require f}

RSpec.configure do |config|
  config.include WebMock::API

  config.before(:each) do
    WebMock.reset!
  end
  config.after(:each) do
    WebMock.reset!
  end
end
