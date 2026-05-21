require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: users(:one).email_address, password: "password123" }
    follow_redirect! if response.redirect?
  end

  test "GET /invitations renders inside the dashboard shell" do
    get invitations_path
    assert_response :success
    # The dashboard layout has the fixed top nav + sidebar. The auth layout
    # has neither — it's the split-panel sign-in shell.
    assert_select "aside#sidebar-default"
  end
end
