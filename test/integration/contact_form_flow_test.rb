require "test_helper"

class ContactFormFlowTest < ActionDispatch::IntegrationTest
  test "GET /contact renders the form" do
    get contact_path
    assert_response :success
    assert_select "form[action='#{submit_contact_path}']"
  end

  test "POST /contact with valid payload redirects with notice" do
    post submit_contact_path, params: {
      contact_form: {
        name: "Sara Jenkins", company: "PMC", email: "sara@pmc.co.uk",
        interest: "demo", message: "Ten plus characters of message here.",
        terms_accepted: "1"
      }
    }
    assert_redirected_to contact_path
    follow_redirect!
    assert_select "div[role='status']", /Thanks Sara/
  end

  test "POST /contact with invalid payload re-renders with inline errors" do
    post submit_contact_path, params: {
      contact_form: { name: "", email: "broken", message: "short",
                      interest: "demo", terms_accepted: "1" }
    }
    assert_response :unprocessable_content
    # field_error_proc decorates invalid inputs with aria-invalid + <small>
    assert_select "input[aria-invalid='true']"
    assert_select "small.text-rose-600"
  end
end
