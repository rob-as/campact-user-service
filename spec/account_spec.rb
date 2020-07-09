require 'spec_helper'

describe CampactUserService::Account do
  let(:client) { CampactUserService::Client.new(host: 'test.com') }
  let(:session_id) { '123456abcdef' }
  let(:session_cookie_name) { 'cus-session' }
  let(:user_id) { 'test@example.org' }

  subject {
    CampactUserService::Account.new(client, user_id)
  }

  before(:each) do
    WebMock.disable_net_connect!
  end

  describe '#exists?' do
    it 'should return true where a valid user object is returned' do
      stub_request(:get, "https://test.com/v1/accounts/#{user_id}")
        .to_return(body: {
          "id": "id-123"
        }.to_json)

      expect(subject.exists?).to be_truthy
    end

    it 'should not return true where an invalid user object is returned' do
      stub_request(:get, "https://test.com/v1/accounts/#{user_id}")
        .to_return(body: {
          "error": true
        }.to_json)

      expect(subject.exists?).to be_falsey
    end
  end

  describe 'URI escaping' do
    it 'should escape the user ID in any requests' do
      malicious_user_id = "\11\15"
      malicious_subject = CampactUserService::Account.new(
        client,
        malicious_user_id
      )
      stub_request(:get, "https://test.com/v1/accounts/%09%0D")
        .to_return(body: '', status: 404)

      expect(malicious_subject.exists?).to be_falsey
    end

    it 'should escape "/" characters' do
      malicious_user_id = "foo@example.com/secrets"
      malicious_subject = CampactUserService::Account.new(
        client,
        malicious_user_id
      )
      stub_request(:get, "https://test.com/v1/accounts/foo@example.com%2Fsecrets")
        .to_return(body: '', status: 404)

      expect(malicious_subject.exists?).to be_falsey
    end
  end

  describe '#name' do
    it 'should retrieve all of the names and gender of the user' do
      stub_request(:get, "https://test.com/v1/accounts/#{user_id}")
        .to_return(body: {
          "name": {
            "firstname": "Alice",
            "lastname": "Wu",
            "gender": "female",
            "title": "PhD",
            "fullname": "PhD Alice Wu"
          },
        }.to_json)

      name = subject.name
      expect(name['firstname']).to eq 'Alice'
      expect(name['lastname']).to eq 'Wu'
      expect(name['gender']).to eq 'female'
      expect(name['title']).to eq 'PhD'
      expect(name['fullname']).to eq 'PhD Alice Wu'
    end
  end

  describe '#email' do
    it 'should retrieve the email address of the user' do
      stub_request(:get, "https://test.com/v1/accounts/#{user_id}")
        .to_return(body: {
          "emailaddress": {
            "emailaddress": "foobar@example.com"
          }
        }.to_json)

      email = subject.email
      expect(email).to eq 'foobar@example.com'
    end

    it 'should return nil where no email address is set' do
      stub_request(:get, "https://test.com/v1/accounts/#{user_id}")
        .to_return(body: {
          "emailaddress": {}
        }.to_json)

      email = subject.email
      expect(email).to be_nil
    end
  end

  describe '#address' do
    it 'should retrieve the address of the user' do
      stub_request(:get, "https://test.com/v1/accounts/#{user_id}")
        .to_return(body: {
          "postaladdress": {
            "street": "123 Fake Street",
            "postalcode": "E1234",
            "locality": "London",
            "countrycode": "GB"
          }
        }.to_json)

      address = subject.address
      expect(address['street']).to eq '123 Fake Street'
    end
  end

  describe '#subscribed_to_newsletter?' do
    it 'should be true where the user is subscribed' do
      stub_request(:get, "https://test.com/v1/accounts/#{user_id}")
        .to_return(body: {
          "emailaddress": {
            "emailaddress": "foobar@example.com",
            "subscriptions": [{"type": "newsletter"}]
          }
        }.to_json)

      expect(subject.subscribed_to_newsletter?).to be_truthy
    end

    it 'should be false where the user is not subscribed' do
      stub_request(:get, "https://test.com/v1/accounts/#{user_id}")
        .to_return(body: {
          "emailaddress": {
            "emailaddress": "foobar@example.com",
            "subscriptions": []
          }
        }.to_json)

      expect(subject.subscribed_to_newsletter?).to be_falsey
    end

    it 'should be false where user subscription is different than newsletter' do
      stub_request(:get, "https://test.com/v1/accounts/#{user_id}")
        .to_return(body: {
          "emailaddress": {
            "emailaddress": "foobar@example.com",
            "subscriptions": [{"type": "foo"}]
          }
        }.to_json)

      expect(subject.subscribed_to_newsletter?).to be_falsey
    end
  end

  describe '#allow_prefill?' do
    it 'should allow prefilling where the user has opted-in' do
      stub_request(:get, "https://test.com/v1/accounts/#{user_id}")
        .to_return(body: {
          "preferences": {
            "prefill_forms": "allowed"
          }
        }.to_json)

      expect(subject.allow_prefill?).to be_truthy
    end

    it 'should not allow prefilling where the user has not decided' do
      stub_request(:get, "https://test.com/v1/accounts/#{user_id}")
        .to_return(body: {
          "preferences": {
            "prefill_forms": "undecided"
          }
        }.to_json)

      expect(subject.allow_prefill?).to be_falsey
    end

    it 'should not allow prefilling where the user has opted out' do
      stub_request(:get, "https://test.com/v1/accounts/#{user_id}")
        .to_return(body: {
          "preferences": {
            "prefill_forms": "disallowed"
          }
        }.to_json)

      expect(subject.allow_prefill?).to be_falsey
    end
  end
end
