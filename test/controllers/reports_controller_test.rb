require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: users(:one).email_address, password: "password123" }
    follow_redirect! if response.redirect?
  end

  test "GET /reports renders without raw-SQL errors" do
    get reports_path
    assert_response :success
  end

  test "GET /reports/defects.csv returns CSV body" do
    get reports_defects_csv_path
    assert_response :success
    assert_match %r{text/csv}, response.media_type
    # Header row should at least contain a known column.
    assert_match(/reference|title/i, response.body.lines.first.to_s)
  end
end
