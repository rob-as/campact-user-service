require 'spec_helper'

describe CampactUserService::Client do
  describe 'initialization' do
    let(:options) {
      {
        scheme: 'https',
        host: 'demo.campact.de',
        port: '10003',
        faraday: { a_custom_option: 'foo', adapter: :an_adapter }
      }
    }
    let(:faraday_builder) { double(adapter: true) }

    it 'should initialize connection from options' do
      expect(faraday_builder).to receive(:adapter).with(:an_adapter)

      expect(Faraday).to receive(:new) do |endpoint, initialization_options|
        expect(endpoint).to eq 'https://demo.campact.de:10003'
        expect(initialization_options[:a_custom_option]).to eq 'foo'
      end.and_yield(faraday_builder)

      CampactUserService::Client.new(options)
    end

    it 'should use default faraday options for connection' do
      expect(Faraday).to receive(:new) do |_endpoint, initialization_options|
        expect(initialization_options[:ssl][:verify]).to be_truthy
        expect(initialization_options[:headers]['Accept']).to eq "application/json;q=0.1"
        expect(initialization_options[:headers]['Accept-Charset']).to eq "utf-8"
        expect(initialization_options[:headers]['User-Agent']).to eq 'campact_user_service'
      end.and_yield(faraday_builder)

      CampactUserService::Client.new(options)
    end

    it 'should allow overriding default options' do
      options[:faraday][:ssl] = {verify: false}
      options[:faraday][:headers] = {'Accept'=>'custom-accept-header', 'Accept-Charset'=>'custom-accept-charset-header', 'User-Agent'=>'custom-user-agent-header'}

      expect(Faraday).to receive(:new) do |_endpoint, initialization_options|
        expect(initialization_options[:ssl][:verify]).to be_falsey
        expect(initialization_options[:headers]['Accept']).to eq 'custom-accept-header'
        expect(initialization_options[:headers]['Accept-Charset']).to eq 'custom-accept-charset-header'
        expect(initialization_options[:headers]['User-Agent']).to eq 'custom-user-agent-header'
      end.and_yield(faraday_builder)

      CampactUserService::Client.new(options)
    end
  end

  shared_examples 'error handling' do
    [310, 410, 510].each do |unexpected_status_code|
      it 'should raise error if status code is 3xx, 4xx or 5xx' do
        expect(request_builder).to receive(:url).with('/foo/bar')
        expect(request_builder_options).to receive(:timeout=).with(CampactUserService::Client::TIMEOUT)
        expect(request_builder_options).to receive(:open_timeout=).with(CampactUserService::Client::TIMEOUT)
        allow(response).to receive(:status).and_return(unexpected_status_code)
        allow(response).to receive(:body).and_return('An error occurred')

        expect { subject.send(method_under_test, '/foo/bar') }.to raise_error do |error|
          expect(error).to be_an_instance_of CampactUserService::ResponseError
          expect(error.status_code).to eq(unexpected_status_code)
          expect(error.body).to eq('An error occurred')
        end
      end
    end

    it 'should return nil if status code is 404' do
      expect(request_builder).to receive(:url).with('/foo/bar')
      expect(request_builder_options).to receive(:timeout=).with(CampactUserService::Client::TIMEOUT)
      expect(request_builder_options).to receive(:open_timeout=).with(CampactUserService::Client::TIMEOUT)
      allow(response).to receive(:status).and_return(404)

      response = subject.send(method_under_test, '/foo/bar')

      expect(response).to be_nil
    end
  end

  describe '#get_request' do
    let(:connection) { double }
    let(:request_builder) { double }
    let(:request_builder_options) { double }
    let(:response) { double(body: '') }
    let(:method_under_test) { :get_request }

    subject { CampactUserService::Client.new(host: 'demo.campact.de') }

    before :each do
      expect(Faraday).to receive(:new).and_yield(double(adapter: true)).and_return(connection)
      expect(request_builder).to receive(:options).at_least(:once).and_return(request_builder_options)
      expect(connection).to receive(:get).and_yield(request_builder).and_return(response)
    end

    include_examples 'error handling'

    it 'should perform get request on provided path and return true if response is 204' do
      expect(request_builder).to receive(:url).with('/foo/bar')
      expect(request_builder_options).to receive(:timeout=).with(CampactUserService::Client::TIMEOUT)
      expect(request_builder_options).to receive(:open_timeout=).with(CampactUserService::Client::TIMEOUT)
      allow(response).to receive(:status).and_return(204)

      expect(subject.get_request('/foo/bar')).to be_truthy
    end

    context 'stubbed request builder' do
      let(:headers_builder) { double }

      before :each do
        allow(request_builder).to receive(:url).with('/foo/bar')
        allow(request_builder_options).to receive(:timeout=).with(CampactUserService::Client::TIMEOUT)
        allow(request_builder_options).to receive(:open_timeout=).with(CampactUserService::Client::TIMEOUT)
        allow(request_builder).to receive(:headers).and_return(headers_builder)
      end

      it 'should set cookies sent as string' do
        expect(headers_builder).to receive(:[]=).with('Cookie', 'foo=bar;xyz=abc')
        allow(response).to receive(:status).and_return(200)

        subject.get_request('/foo/bar', cookies: 'foo=bar;xyz=abc')
      end

      it 'should set cookies sent as hash' do
        expect(headers_builder).to receive(:[]=).with('Cookie', 'foo=bar;xyz=abc;')
        allow(response).to receive(:status).and_return(200)

        subject.get_request('/foo/bar', cookies: {'foo' => 'bar', 'xyz' => 'abc'})
      end

      it 'should set TOTP authorization header' do
        allow(response).to receive(:status).and_return(200)
        allow(response).to receive(:body).and_return(nil)

        totp_secret = Base32.encode('shh! a secret!').gsub('=', '')

        totp = double
        expect(totp).to receive(:now).and_return('totp_token')
        expect(ROTP::TOTP).to receive(:new).with(totp_secret, hash_including(digest: 'sha256', digits: 8, interval: 30)).and_return(totp)

        expect(headers_builder).to receive(:[]=).with('authorization', 'Token api_user:totp_token')

        subject = CampactUserService::Client.new(host: 'demo.campact.de', topt_authorization: {user: 'api_user', secret: 'shh! a secret!'})

        subject.get_request('/foo/bar')
      end

      it 'should parse JSON response on successful response' do
        allow(response).to receive(:status).and_return(200)
        allow(response).to receive(:body).and_return({a_field: 'foo', another_field: 'bar'}.to_json)

        response = subject.get_request('/foo/bar')

        expect(response).not_to be_nil
        expect(response['a_field']).to eq 'foo'
        expect(response['another_field']).to eq 'bar'
      end
    end
  end

  describe '#delete_request' do
    let(:connection) { double }
    let(:request_builder) { double }
    let(:request_builder_options) { double }
    let(:response) { double(body: '') }
    let(:method_under_test) { :delete_request }

    subject { CampactUserService::Client.new(host: 'demo.campact.de') }

    before :each do
      expect(Faraday).to receive(:new).and_yield(double(adapter: true)).and_return(connection)
      expect(request_builder).to receive(:options).at_least(:once).and_return(request_builder_options)
      expect(connection).to receive(:delete).and_yield(request_builder).and_return(response)
    end

    include_examples 'error handling'
  end
end
