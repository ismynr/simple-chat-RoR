require 'cgi'

class MessagesController < ApplicationController
    # GET /conversation/:conversation_id/messages
    def index
        user = user_auth
        conversation_id = request.path_parameters[:conversation_id] || params[:conversation_id]
        
        @conversations = Conversation.find(conversation_id)
        @messages = ConversationMessage.where(conversation_id: conversation_id)

        # if the conversation is not hers
        if @conversations.user_id != user.id
            json_response("You don't have access for this resource", :forbidden)
            return
        end

        modified_messages = @messages.map do |message|
            {
              id: message.id,
              message: message.content,
              sender: {
                id: message.user.id,
                name: message.user.name,
              },
              sent_at: message.created_at,
            }
        end

        json_response(modified_messages, :ok)
    end

    # POST /messages
    def create
        user = user_auth

        # decode request value post
        decoded_values = CGI.parse(request.raw_post)
        user_id = decoded_values["user_id"].first || params[:user_id]
        content = decoded_values["message"].first || params[:message]

        # validation of request
        if content === '' || user_id === ''
            json_response("message cannot be null", :unprocessable_entity)
            return 
        end

        existConvoParticipantUser1 = ConversationParticipant.where(user_id: user_id).pluck(:conversation_id)
        existConvoParticipantUser2 = ConversationParticipant.where(user_id: user.id).pluck(:conversation_id)
        sender = User.find_by(id: user.id)
        receiver = User.find_by(id: user_id)

        haveAnyConversation = existConvoParticipantUser1 & existConvoParticipantUser2

        # Existing Conversation
        if (haveAnyConversation.any?)
            conversation_id_indice = nil
            existConvoParticipantUser1.each_with_index do |element, index|
                if haveAnyConversation.include?(element)
                    conversation_id_indice = element
                    break
                end
            end
            if (conversation_id_indice != nil)
                @message = ConversationMessage.create!(content: content, user_id: user.id, conversation_id: conversation_id_indice)
                convoParticipantUser1 = ConversationParticipant.where(user_id: user_id, conversation_id: conversation_id_indice).first
                unread_count = convoParticipantUser1.unread_count+1
                convoParticipantUser1.update!(unread_count: unread_count)
                json_response({
                    id: @message.id,
                    message: @message.content,
                    sender: {
                        id: user.id,
                        name: sender.name,
                    },
                    sent_at: @message.created_at,
                    conversation: {
                        id: conversation_id_indice,
                        with_user: {
                            id: receiver.id,
                            name: receiver.name,
                            photo_url: receiver.photo_url,
                        },
                    },
                }, :created)
                return 
            end
        end
        
        # New Conversation
        @conversation = Conversation.create!(user_id: user.id)
        @participant = ConversationParticipant.create!(user_id: user_id, conversation_id: @conversation.id, unread_count: 1)
        @participant = ConversationParticipant.create!(user_id: user.id, conversation_id: @conversation.id, unread_count: 0)
        @message = ConversationMessage.create!(content: content, user_id: user.id, conversation_id: @conversation.id)
        json_response({
            id: @message.id,
            message: @message.content,
            sender: {
                id: user.id,
                name: sender.name,
            },
            sent_at: @message.created_at,
            conversation: {
                id: @conversation.id,
                with_user: {
                    id: receiver.id,
                    name: receiver.name,
                    photo_url: receiver.photo_url,
                },
            },
        }, :created)
    end

    # Get auth and decode to user model
    def user_auth
        authorize_request = AuthorizeApiRequest.new(request.headers)
        result = authorize_request.call
        user = result[:user]
        return user
    end
end
