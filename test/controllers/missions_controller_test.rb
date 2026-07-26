require "test_helper"

class MissionsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get missions_create_url
    assert_response :success
  end

  test "should get destroy" do
    get missions_destroy_url
    assert_response :success
  end
end
