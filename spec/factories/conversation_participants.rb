FactoryBot.define do
  factory :conversation_participant do
    user_id nil
    conversation_id nil
    unread_count 0
  end
end
