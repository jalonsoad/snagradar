require "test_helper"

class SearchTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: users(:one).email_address, password: "password123" }
    follow_redirect! if response.redirect?
  end

  test "GET /search ignores short queries" do
    get search_path, params: { q: "x" }
    assert_response :success
    assert_select "h3", /No matches/
  end

  test "GET /search.json returns defect matches" do
    get search_path(format: :json), params: { q: "leak" }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_includes body["defects"].map { |d| d["title"] }, "Leak under kitchen sink"
  end

  test "GET /search.json returns site matches" do
    get search_path(format: :json), params: { q: "adur" }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_includes body["sites"].map { |s| s["name"] }, "Adur Shoreham"
  end
end
