require "test_helper"

class XtransfersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get xtransfers_index_url
    assert_response :success
  end

  test "should get new" do
    get xtransfers_new_url
    assert_response :success
  end

  test "should get create" do
    get xtransfers_create_url
    assert_response :success
  end

  test "should get edit" do
    get xtransfers_edit_url
    assert_response :success
  end

  test "should get update" do
    get xtransfers_update_url
    assert_response :success
  end

  test "should get destroy" do
    get xtransfers_destroy_url
    assert_response :success
  end

  test "should get toggle_pending" do
    get xtransfers_toggle_pending_url
    assert_response :success
  end

  test "should get accounts" do
    get xtransfers_accounts_url
    assert_response :success
  end
end
