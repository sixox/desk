require "test_helper"

class GameControllerTest < ActionDispatch::IntegrationTest
  test "should get quardo" do
    get game_quardo_url
    assert_response :success
  end
end
