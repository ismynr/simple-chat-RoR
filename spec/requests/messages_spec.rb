require 'rails_helper'

RSpec.describe 'Messages API', type: :request do
  # Changes reason: should run before all in context to create dummy data
  before(:context) do
    @agus = create(:user)
    @agus_headers = valid_headers(@agus.id)
    @dimas = create(:user)
    @dimas_headers = valid_headers(@dimas.id)
    @samid = create(:user)
    @samid_headers = valid_headers(@samid.id)

    # TODO: create conversation between Dimas and Agus, then set convo_id variable
    @convo = create(:conversation, user_id: @dimas.id)
    @convo_participantAgus = create(:conversation_participant, user_id: @agus.id, conversation_id: @convo.id, unread_count: 1)
    @convo_participantDimas = create(:conversation_participant, user_id: @dimas.id, conversation_id: @convo.id, unread_count: 0)
    @convo_messages = create(:conversation_message, user_id: @dimas.id, conversation_id: @convo.id)
    @convo_id = @convo.id
  end

  describe 'get list of messages' do
    context 'when user have conversation with other user' do
      before { get "/conversations/#{@convo_id}/messages", params: {}, headers: @dimas_headers }

      it 'returns list all messages in conversation' do
        # Changes reason: always error when use be_json_type function
        expect_response(:ok)
        expect(response_data[0][:id]).to be_a(Integer)
        expect(response_data[0][:message]).to be_a(String)
        expect(response_data[0][:sender][:id]).to be_a(Integer)
        expect(response_data[0][:sender][:name]).to be_a(String)
        expect(response_data[0][:sent_at]).to be_a(String)
        conversationParticipant = ConversationParticipant.where(user_id: @agus.id, conversation_id: @convo.id).first
        expect(1).to eq(conversationParticipant.unread_count)
      end
    end

    context 'when user another user read message lists' do
      before { get "/conversations/#{@convo_id}/messages", params: {}, headers: @agus_headers }
      
      it 'reset unread count' do
        conversationParticipant = ConversationParticipant.where(user_id: @agus.id, conversation_id: @convo.id).first
        expect_response(:ok)
        expect(0).to eq(conversationParticipant.unread_count)
      end
    end

    context 'when user try to access conversation not belong to him' do
      # TODO: create conversation and set convo_id variable
      before { get "/conversations/#{@convo_id}/messages", params: {}, headers: @samid_headers }

      it 'returns error 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'when user try to access invalid conversation' do
      # TODO: create conversation and set convo_id variable
      before { get "/conversations/-11/messages", params: {}, headers: @samid_headers }

      it 'returns error 404' do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'send message' do
    let(:valid_attributes) do
      { message: 'Hi there!', user_id: @agus.id }
    end

    let(:invalid_attributes) do
      { message: '', user_id: @agus.id }
    end

    context 'when request attributes are valid' do
      before { post "/messages", params: valid_attributes, headers: @dimas_headers}

      it 'returns status code 201 (created) and create conversation automatically' do
        expect_response(:created)
        # Changes reason: always error when use be_json_type function
        expect(response_data[:id]).to be_a(Integer)
        expect(response_data[:message]).to be_a(String)
        expect(response_data[:sender][:id]).to be_a(Integer)
        expect(response_data[:sender][:name]).to be_a(String)
        expect(response_data[:sent_at]).to be_a(String)
        expect(response_data[:conversation][:id]).to be_a(Integer)
        expect(response_data[:conversation][:with_user][:id]).to be_a(Integer)
        expect(response_data[:conversation][:with_user][:name]).to be_a(String)
        expect(response_data[:conversation][:with_user][:photo_url]).to be_a(String)
      end
    end

    context 'when create message into existing conversation' do
      before { post "/messages", params: valid_attributes, headers: @dimas_headers}

      it 'returns status code 201 (created) and create conversation automatically' do
        # Changes reason: always error when use be_json_type function
        expect_response(:created)
        expect(response_data[:id]).to be_a(Integer)
        expect(response_data[:message]).to be_a(String)
        expect(response_data[:sender][:id]).to be_a(Integer)
        expect(response_data[:sender][:name]).to be_a(String)
        expect(response_data[:sent_at]).to be_a(String)
        expect(response_data[:conversation][:id]).to eq(@convo_id)
        expect(response_data[:conversation][:with_user][:id]).to be_a(Integer)
        expect(response_data[:conversation][:with_user][:name]).to be_a(String)
        expect(response_data[:conversation][:with_user][:photo_url]).to be_a(String)
      end
    end

    context 'when an invalid request' do
      before { post "/messages", params: invalid_attributes, headers: @dimas_headers}

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end
    end
  end
end
