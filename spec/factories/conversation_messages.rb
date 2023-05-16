FactoryBot.define do
  factory :conversation_message do
    user_id nil
    conversation_id nil
    content { Faker::Lorem.sentence }
  end
end
  