class User < ApplicationRecord
  has_many :participants, dependent: :destroy
  has_many :conversations, through: :participants
  has_many :messages, dependent: :destroy

  # encrypt password
  has_secure_password
end
