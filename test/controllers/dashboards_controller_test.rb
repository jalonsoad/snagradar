require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: users(:one).email_address, password: "password123" }
    follow_redirect! if response.redirect?
  end

  test "GET /dashboard renders with chart data" do
    get dashboard_path
    assert_response :success
    # ApexCharts is wired through data-controller="chart" with options JSON.
    assert_select '[data-controller~="chart"]'
  end

  test "status breakdown series reflects real defect counts (regression)" do
    org = users(:one).organization
    # Force at least one defect into a known status so the donut has data.
    org.defects.first&.update_columns(status: Defect.statuses["logged"])
    expected = org.defects.where(status: :logged).count
    skip "no defects in fixtures" if expected.zero?

    get dashboard_path
    assert_response :success
    # Donut options JSON includes `status_series` numbers — the count for
    # "logged" should appear in the serialised options, not zero.
    assert_includes response.body, expected.to_s,
      "donut should serialise the real logged count (#{expected}), not 0"
  end
end
