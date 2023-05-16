class ConversationsController < ApplicationController
    # GET /conversations
    def index
        user = user_auth
        @conversationParticipant = ConversationParticipant.where(user_id: user.id)

        modified_conversations = @conversationParticipant.map do |itemCp|
            @lastConversationMessage = ConversationMessage.where(conversation_id: itemCp.conversation_id).order(created_at: :desc).first
            @conversationParticipantWith = ConversationParticipant.where.not(user_id: user.id).where(conversation_id: itemCp.conversation_id).first
            {
                id: itemCp.conversation_id,
                with_user: {
                    id: @conversationParticipantWith.user.id,
                    name: @conversationParticipantWith.user.name,
                    photo_url: @conversationParticipantWith.user.photo_url,
                },
                last_message: {
                    id: @lastConversationMessage.id,
                    sender: {
                        id: @lastConversationMessage.user.id,
                        name: @lastConversationMessage.user.name,
                    },
                    message: @lastConversationMessage.content,
                    sent_at: @lastConversationMessage.created_at,
                },
                unread_count: itemCp.unread_count
            }
        end

        return json_response(modified_conversations, :ok)
    end

    # GET /conversations/:id
    def show
        user = user_auth
        conversation_id = request.path_parameters[:id] || params[:id]
        @conversation = Conversation.find(conversation_id)
        @conversationParticipant = ConversationParticipant.where(conversation_id: conversation_id).where.not(user_id: user.id).first

        # if the conversation is not hers
        if @conversation.user_id != user.id
            json_response("You don't have access for this resource", :forbidden)
            return
        end

        json_response({
            id: @conversation.id,
            with_user: {
                id: @conversationParticipant.user.id,
                name: @conversationParticipant.user.name,
                photo_url: @conversationParticipant.user.photo_url,
            },
        }, :ok)
    end

    # Get auth and decode to user model
    def user_auth
        authorize_request = AuthorizeApiRequest.new(request.headers)
        result = authorize_request.call
        user = result[:user]
        return user
    end
end
