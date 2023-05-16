class Conversation < ApplicationRecord
    belongs_to :user
    has_many :conversation_message, dependent: :destroy
    has_many :conversation_participant, dependent: :destroy
end
