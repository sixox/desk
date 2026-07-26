require "application_system_test_case"

class ZahrasTest < ApplicationSystemTestCase
  setup do
    @zahra = zahras(:one)
  end

  test "visiting the index" do
    visit zahras_url
    assert_selector "h1", text: "Zahras"
  end

  test "should create zahra" do
    visit zahras_url
    click_on "New zahra"

    fill_in "Family", with: @zahra.family
    fill_in "Name", with: @zahra.name
    fill_in "Phone", with: @zahra.phone
    click_on "Create Zahra"

    assert_text "Zahra was successfully created"
    click_on "Back"
  end

  test "should update Zahra" do
    visit zahra_url(@zahra)
    click_on "Edit this zahra", match: :first

    fill_in "Family", with: @zahra.family
    fill_in "Name", with: @zahra.name
    fill_in "Phone", with: @zahra.phone
    click_on "Update Zahra"

    assert_text "Zahra was successfully updated"
    click_on "Back"
  end

  test "should destroy Zahra" do
    visit zahra_url(@zahra)
    click_on "Destroy this zahra", match: :first

    assert_text "Zahra was successfully destroyed"
  end
end
