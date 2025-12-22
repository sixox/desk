require "test_helper"

class PayrollAttendancesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get payroll_attendances_index_url
    assert_response :success
  end

  test "should get show" do
    get payroll_attendances_show_url
    assert_response :success
  end
end
