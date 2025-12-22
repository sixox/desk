require "test_helper"

class UserManagerMappingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get user_manager_mappings_index_url
    assert_response :success
  end

  test "should get update" do
    get user_manager_mappings_update_url
    assert_response :success
  end
end
