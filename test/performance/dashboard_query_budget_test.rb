require "test_helper"

# Lightweight perf probe — guards against N+1 regressions on the dashboard.
# Counts SQL queries needed to render /dashboard. If a future change blows
# past the budget, the test fails fast in CI.
class DashboardQueryBudgetTest < ActionDispatch::IntegrationTest
  QUERY_BUDGET = 60

  setup do
    post session_path, params: { email_address: users(:one).email_address, password: "password123" }
    follow_redirect! if response.redirect?
  end

  test "GET /dashboard stays under the query budget" do
    queries = capture_query_count { get dashboard_path }
    assert_response :success
    assert queries <= QUERY_BUDGET,
      "Dashboard issued #{queries} SQL queries (budget: #{QUERY_BUDGET}). Likely an N+1 — add .includes() or eager_load."
  end

  private

  def capture_query_count
    count = 0
    callback = ->(_name, _start, _finish, _id, payload) {
      next if payload[:name].in?([ "SCHEMA", "TRANSACTION", "CACHE" ])
      count += 1
    }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    count
  end
end
