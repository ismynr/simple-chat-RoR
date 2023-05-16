require 'rails_helper'

RSpec.describe 'Conversations API', type: :request do
  # Changes reason: should run before all in context to create dummy data
  before(:context) do
    @dimas = create(:user)
    @dimas_headers = valid_headers(@dimas.id)
    @samid = create(:user)
    @samid_headers = valid_headers(@samid.id)
    @agus = create(:user)
    @agus_headers = valid_headers(@agus.id)

    for i in 1..5
      @convo = create(:conversation, user_id: @dimas.id)
      @convo_participant = create(:conversation_participant, user_id: @samid.id, conversation_id: @convo.id, unread_count: 1)
      @convo_participant = create(:conversation_participant, user_id: @dimas.id, conversation_id: @convo.id, unread_count: 0)
      @convo_messages = create(:conversation_message, user_id: @dimas.id, conversation_id: @convo.id)
      @convo_id = @convo.id
    end
  end

  describe 'GET /conversations' do
    context 'when user have no conversation' do
      # make HTTP get request before each example
      # Changes reason: for identify agus have no conversation with another person
      before { get '/conversations', params: {}, headers: @agus_headers }

      it 'returns empty data with 200 code' do
        # Changes reason: always error when use be_json_type function
        expect_response(:ok)
        expect(response_data).to match([])
      end
    end

    context 'when user have conversations' do
      # TODOS: Populate database with conversation of current user

      before { get '/conversations', params: {}, headers: @dimas_headers }

      it 'returns list conversations of current user' do
        # Note `response_data` is a custom helper
        # to get data from parsed JSON responses in spec/support/request_spec_helper.rb

        expect(response_data).not_to be_empty
        expect(response_data.size).to eq(5)
      end

      it 'returns status code 200 with correct response' do
        # Changes reason: always error when use be_json_type function
        expect_response(:ok)
        expect(response_data[0][:id]).to be_a(Integer)
        expect(response_data[0][:with_user][:id]).to be_a(Integer)
        expect(response_data[0][:with_user][:name]).to be_a(String)
        expect(response_data[0][:with_user][:photo_url]).to be_a(String)
        expect(response_data[0][:last_message][:id]).to be_a(Integer)
        expect(response_data[0][:last_message][:sender][:id]).to be_a(Integer)
        expect(response_data[0][:last_message][:sender][:name]).to be_a(String)
        expect(response_data[0][:last_message][:sent_at]).to be_a(String)
        expect(response_data[0][:unread_count]).to be_a(Integer)
      end
    end
  end

  describe 'GET /conversations/:id' do
    context 'when the record exists' do
      # TODO: create conversation of dimas
      before { get "/conversations/#{@convo_id}", params: {}, headers: @dimas_headers }

      it 'returns conversation detail' do
        # Changes reason: always error when use be_json_type function
        expect_response(:ok)
        expect(response_data[:id]).to be_a(Integer)
        expect(response_data[:with_user][:id]).to be_a(Integer)
        expect(response_data[:with_user][:name]).to be_a(String)
        expect(response_data[:with_user][:photo_url]).to be_a(String)
      end
    end

    context 'when current user access other user conversation' do
      before { get "/conversations/#{@convo_id}", params: {}, headers: @samid_headers }

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'when the record does not exist' do
      before { get "/conversations/-11", params: {}, headers: @dimas_headers }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end
    end
  end
end