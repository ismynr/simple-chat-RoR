module ControllerSpecHelper
  # generate tokens from user id
  def token_generator(user_id)
    # Changes reason: wrong convert, and can't be decode if use user object directly
    if user_id.is_a?(User)
      user_id = user_id.id
    end
    JsonWebToken.encode(user_id: user_id)
  end

  # generate expired tokens from user id
  def expired_token_generator(user_id)
    # Changes reason: wrong convert, and can't be decode if use user object directly
    if user_id.is_a?(User)
      user_id = user_id.id
    end
    JsonWebToken.encode({ user_id: user_id }, (Time.now.to_i - 10))
  end

  # return valid headers
  def valid_headers(user_id)
    {
      "Authorization" => token_generator(user_id),
      "Content-Type" => "application/json"
    }
  end

  # return invalid headers
  def invalid_headers
    {
      "Authorization" => nil,
      "Content-Type" => "application/json"
    }
  end
end