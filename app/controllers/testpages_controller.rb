class TestpagesController < AuthenticatedController
  def show
    @testpage_messages = TestpageMessage.recent.limit(20)
    @calendar_anchor   = parse_month(params[:testpage_month]) || Date.current
  end

  private

  def parse_month(raw)
    return nil if raw.blank?
    Date.strptime(raw.to_s, "%Y-%m")
  rescue Date::Error
    nil
  end
end
