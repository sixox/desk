require "test_helper"

class ZahrasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @zahra = zahras(:one)
  end

  test "should get index" do
    get zahras_url
    assert_response :success
  end

  test "should get new" do
    get new_zahra_url
    assert_response :success
  end

  test "should create zahra" do
    assert_difference("Zahra.count") do
      post zahras_url, params: { zahra: { family: @zahra.family, name: @zahra.name, phone: @zahra.phone } }
    end

    assert_redirected_to zahra_url(Zahra.last)
  end

  test "should show zahra" do
    get zahra_url(@zahra)
    assert_response :success
  end

  test "should get edit" do
    get edit_zahra_url(@zahra)
    assert_response :success
  end

  test "should update zahra" do
    patch zahra_url(@zahra), params: { zahra: { family: @zahra.family, name: @zahra.name, phone: @zahra.phone } }
    assert_redirected_to zahra_url(@zahra)
  end

  test "should destroy zahra" do
    assert_difference("Zahra.count", -1) do
      delete zahra_url(@zahra)
    end

    assert_redirected_to zahras_url
  end
end
