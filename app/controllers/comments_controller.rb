class CommentsController < AuthenticatedController
  def create
    defect  = Current.organization.defects.find(params[:defect_id])
    comment = defect.comments.build(comment_params.merge(user: Current.user, organization: Current.organization))

    if comment.save
      ActivityEvent.log!(defect: defect, type: "comment.added", actor: Current.user,
                         metadata: { visibility: comment.visibility })
      redirect_to defect_path(defect), status: :see_other
    else
      redirect_to defect_path(defect), status: :see_other, alert: "Comment can't be empty."
    end
  end

  private

  def comment_params
    params.expect(comment: [ :body, :visibility ])
  end
end
