class TestpageMessagesController < AuthenticatedController
  before_action :set_message, only: :destroy

  def create
    body = params.dig(:testpage_message, :body).to_s.strip
    kind = params.dig(:testpage_message, :kind).to_s.presence_in(TestpageMessage::KINDS) || "info"

    TestpageMessage.create!(body: body.presence || "Hello from #{Current.user.display_name}!", kind: kind)
    enforce_cap

    # The model's after_create_commit broadcast_prepend_to already updates
    # the feed in every subscribed tab. For the submitting tab we just clear
    # the textarea so the user can post again without losing scroll position.
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("testpage_message_compose", partial: "testpage_messages/form") }
      format.html         { redirect_to testpage_path, status: :see_other }
    end
  end

  def destroy
    @message.destroy
    respond_to do |format|
      format.turbo_stream { head :no_content }     # broadcast_remove_to handles the UI
      format.html         { redirect_to testpage_path, status: :see_other }
    end
  end

  def destroy_all
    TestpageMessage.find_each(&:destroy)
    respond_to do |format|
      format.turbo_stream { head :no_content }
      format.html         { redirect_to testpage_path, status: :see_other }
    end
  end

  private

  def set_message
    @message = TestpageMessage.find(params[:id])
  end

  # Keep the demo feed tidy — only the most recent N messages are kept.
  def enforce_cap
    surplus = TestpageMessage.order(created_at: :desc).offset(20)
    surplus.find_each(&:destroy)
  end
end
