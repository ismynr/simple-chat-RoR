class CreateConversationParticipants < ActiveRecord::Migration[6.1]
  def change
    create_table :conversation_participants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.integer :unread_count

      t.timestamps
    end
  end
end
