require "test_helper"

class MarketingPagesTest < ActionDispatch::IntegrationTest
  test "all public pages render without auth" do
    [ root_path, features_path, pricing_path, about_path, contact_path, privacy_path, terms_path ].each do |path|
      get path
      assert_response :success, "#{path} did not return 200"
    end
  end

  test "authenticated routes redirect to sign-in when unauthenticated" do
    get dashboard_path
    assert_redirected_to new_session_path
  end
end
