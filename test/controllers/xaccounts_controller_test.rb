require "test_helper"

class XaccountsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get xaccounts_new_url
    assert_response :success
  end

  test "should get show" do
    get xaccounts_show_url
    assert_response :success
  end

  test "should get edit" do
    get xaccounts_edit_url
    assert_response :success
  end
end
