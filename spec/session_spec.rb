require 'spec_helper'

describe CampactUserService::Session do
  let(:client) { CampactUserService::Client.new(host: 'test.com') }
  let(:session_id) { '123456abcdef' }
  let(:session_cookie_name) { 'cus-session' }

  subject { CampactUserService::Session.new(client, session_id, session_cookie_name) }

  describe '#user_id' do
    it 'should be present' do
      stub_request(:get, 'https://test.com/v1/sessions')
        .with(headers: {'Cookie' => "cus-session=#{session_id};"})
        .to_return(body: {user_id: 'user@example.org'}.to_json)

      expect(subject.user_id).to eq('user@example.org')
    end
  end
end
