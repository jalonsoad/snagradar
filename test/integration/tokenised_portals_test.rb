require "test_helper"

class TokenisedPortalsTest < ActionDispatch::IntegrationTest
  setup { @defect = defects(:leaking_sink) }

  test "contractor portal renders with valid token" do
    get contractor_portal_path(token: @defect.contractor_token)
    assert_response :success
    assert_select "h1", /Leak under kitchen sink/
  end

  test "contractor portal returns 410 for invalid token" do
    get contractor_portal_path(token: "definitely-not-real")
    assert_response :gone
  end

  test "resident sign-off page renders the signature canvas" do
    get resident_signoff_path(token: @defect.resident_signoff_token)
    assert_response :success
    assert_select "canvas[data-signature-pad-target='canvas']"
  end

  test "resident sign-off rejects tampered tokens" do
    get resident_signoff_path(token: "tampered")
    assert_response :gone
  end

  test "contractor accept transitions state and logs activity" do
    assert_difference -> { @defect.activity_events.count } => 1 do
      post contractor_portal_accept_path(token: @defect.contractor_token)
    end
    assert_equal "accepted", @defect.reload.status
  end
end
