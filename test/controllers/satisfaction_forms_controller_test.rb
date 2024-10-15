require "test_helper"

class SatisfactionFormsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get satisfaction_forms_index_url
    assert_response :success
  end

  test "should get update_all" do
    get satisfaction_forms_update_all_url
    assert_response :success
  end
end
