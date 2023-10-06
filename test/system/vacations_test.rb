require "application_system_test_case"

class VacationsTest < ApplicationSystemTestCase
  setup do
    @vacation = vacations(:one)
  end

  test "visiting the index" do
    visit vacations_url
    assert_selector "h1", text: "Vacations"
  end

  test "should create vacation" do
    visit vacations_url
    click_on "New vacation"

    fill_in "Comment", with: @vacation.comment
    check "Confirm" if @vacation.confirm
    fill_in "Details", with: @vacation.details
    fill_in "End at", with: @vacation.end_at
    fill_in "Start at", with: @vacation.start_at
    fill_in "Status", with: @vacation.status
    fill_in "Type", with: @vacation.type
    fill_in "User", with: @vacation.user_id
    click_on "Create Vacation"

    assert_text "Vacation was successfully created"
    click_on "Back"
  end

  test "should update Vacation" do
    visit vacation_url(@vacation)
    click_on "Edit this vacation", match: :first

    fill_in "Comment", with: @vacation.comment
    check "Confirm" if @vacation.confirm
    fill_in "Details", with: @vacation.details
    fill_in "End at", with: @vacation.end_at
    fill_in "Start at", with: @vacation.start_at
    fill_in "Status", with: @vacation.status
    fill_in "Type", with: @vacation.type
    fill_in "User", with: @vacation.user_id
    click_on "Update Vacation"

    assert_text "Vacation was successfully updated"
    click_on "Back"
  end

  test "should destroy Vacation" do
    visit vacation_url(@vacation)
    click_on "Destroy this vacation", match: :first

    assert_text "Vacation was successfully destroyed"
  end
end
