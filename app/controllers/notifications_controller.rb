class NotificationsController < AuthenticatedController
  def index
    @notifications = Current.user.notifications
      .where(organization: Current.organization)
      .includes(:defect)
      .recent
      .limit(50)

    Current.user.notifications.unread.update_all(read_at: Time.current, status: :read)
  end

  def update
    notification = Current.user.notifications.find(params[:id])
    notification.update!(read_at: Time.current, status: :read)
    redirect_back fallback_location: notifications_path, status: :see_other
  end
end
